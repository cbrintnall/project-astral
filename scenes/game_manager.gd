extends Node
class_name GameManager

static var inst: GameManager

signal points_fx

@export var camera: Camera3D
@export var selection_svp: SubViewport
@export var enemy_tile_container: EnemyTileContainer

@export var light: DirectionalLight3D

var current_score: int = 0:
  set(val):
    current_score = maxi(val, 0)
  get:
    return current_score
var required_score: int:
  get:
    return Constants.REQUIRED_SCORES[mini(cycle, len(Constants.REQUIRED_SCORES)-1)]

var active_execution: ExecutionContext:
  get:
    return _current_context

var cycle := 0
var turn := 0

var player_tasks := TaskGroup.new()
var money := 0

var current_state: String:
  get:
    return _state.current

var won := false

var _background_color := Color.from_string("#272744", Color.WHITE)

var _state := CallableStateMachine.new()
var _deal_timer := BetterTimer.new(0.1)

var _initiate_tiles := []
var _current_context: ExecutionContext
var _execution_order := []
var _pre_execution_order := []
var _post_execution_order := []

var _sound_counter := 0.0
var _reset_sound_timer := BetterTimer.new(1.0)

var _play_timer := BetterTimer.new(1.0)

var _set_enemy_timer := BetterTimer.new(1.0)
var _enemy_queue := {}

var _execution_queue := []

func get_current_execution_queue() -> Array:
  match _state.current:
    "pre_execute":
      return _pre_execution_order
    "execute":
      return _execution_order
    "post_execute":
      return _post_execution_order
  return []

func enter_shop():
  assert(current_state == "wait_for_accept_shop")
  _state.current = "shop"
  ShopManager.inst.enter()

func leave_shop():
  assert(current_state == "shop")
  _state.current = "start_round"

func do_receive_points_fx():
  _sound_counter += 0.01
  
  AudioManager3d.play({
    "stream": preload("res://audio/Light Drone Sound (button hover) 9.wav"),
    "pitch_additional": _sound_counter,
    "debounce": 0.05
  })
  
  _reset_sound_timer.reset()
  points_fx.emit()

func try_execute_turn():
  _state.current = "begin_execution"
  TileHand.inst.discard_hand()

func _ready() -> void:
  DebugDraw2D.debug_enabled = false
  Console.pause_enabled = true

  _current_context = ExecutionContext.new()
  
  inst = self
  add_child(_state)
  add_child(player_tasks)
  
  _state.register("start_round", _start_round)
  _state.register("deal", _deal)
  _state.register("wait_for_player", _wait_for_player)
  _state.register("begin_execution", _begin_execution)
  _state.register("pre_execute", _pre_execute)
  _state.register("execute", _execute_turn)
  _state.register("post_execute", _post_execute)
  _state.register("post_round", _post_round)
  _state.register("shop", _shop)
  _state.register("enemies", _distribute_enemies)
  _state.register("wait_for_accept_shop", CallableStateMachine.noop)
  _state.register("end_game", _end_game)
  
  selection_svp.world_3d = get_viewport().find_world_3d()
  
  _state.state_changed.connect(
    func(state):
      print("game state changed: %s" % state)
  )
  
  await Utils.wait_until(func(): return GridManager.inst != null)
  
  var start_tile = load("res://scenes/board/tile.tscn").instantiate()
  start_tile.def = load("res://data/tiles/tile_source_tile.tres")
  assert(GridManager.inst.try_place_tile(start_tile, Vector3i.ZERO), "This should never fail")
  GridManager.inst.center_tile = start_tile
  BoardCamera.inst.try_set_focus(GridManager.inst.map_to_global(Vector3i.ZERO))
  #var start_mesh: MeshInstance3D = NodeUtils.find_child_with_predicate(start_tile, func(node): return node is MeshInstance3D)
  #start_mesh.material_override = preload("res://materials/material_debug.tres")
  var start_mesh: MeshInstance3D = NodeUtils.find_child_with_predicate(start_tile, func(node): return node is MeshInstance3D)
  if start_mesh:
      start_mesh.queue_free()
  var eos = load("res://assets/blender/objects/Eos.glb").instantiate()
  start_tile.add_child(eos)
  UI.inst.show_system_message("Begin Cycle")
  
  Console.add_command(
    "lose",
    func(): 
      _state.current = "end_game"
      UI.inst.show_system_message("You've lost, plunging the world into eternal night.")
  )
  
  Console.add_command(
    "won",
    func():
        _state.current = "end_game"
        won = true
        UI.inst.show_system_message("You've won, defeating the eternal night.")
  )
  
  Console.add_command(
    "debug",
    func():
      DebugDraw2D.debug_enabled = not DebugDraw2D.debug_enabled
  )
  
func _process(delta: float) -> void:
  if _reset_sound_timer.check(delta):
    _sound_counter = 0.0
    
  selection_svp.physics_object_picking = _state.current != "shop"
  
func _end_game(machine: CallableStateMachine, delta: float):
  if not won:
    light.light_energy = move_toward(light.light_energy, 0.0, delta)
  else:
    light.light_energy = move_toward(light.light_energy, 2.0, delta)
    _background_color = _background_color.lerp(Color.from_string("#c69fa5", Color.WHITE), 0.01)
    RenderingServer.global_shader_parameter_set("world_background", _background_color)
  
func _start_round(machine: CallableStateMachine, delta: float):
  turn += 1
  
  BoardCamera.inst.map_size = GridManager.inst.size
  BoardCamera.inst.map_root = Vector3.ZERO
  BoardCamera.inst.try_set_focus(Vector3.ZERO)
  
  _pre_execution_order = GridManager.inst.get_played_tiles().filter(func(tile: Tile): return tile.has_pre_round_effects())
  _maintain_queue(_pre_execution_order)
  print(_pre_execution_order)
  
  _state.current = "pre_execute"
  
func _deal(machine: CallableStateMachine, delta: float):
  if TileHand.inst.get_tile_count() >= Constants.DEFAULT_HAND_SIZE:
    _state.current = "wait_for_player"
    return
  
  if _deal_timer.check(delta):
    var next = HandManager.inst.get_next_from_hand()
    TileHand.inst.add_to_hand(next)

func _wait_for_player(machine: CallableStateMachine, delta: float):
  pass

func _post_round(machine: CallableStateMachine, delta: float):
  if current_score >= required_score:
    money += 1
  
  if turn >= Constants.TURNS_PER_SCORE:
    if current_score >= required_score:
      if cycle >= len(Constants.REQUIRED_SCORES)-1:
        won = true
        _state.current = "end_game"
        UI.inst.show_system_message("You've won, defeating the eternal night.")
        return
      
      UI.inst.show_system_message("Begin Cycle")
      cycle += 1
      turn = 0
      _current_context = ExecutionContext.new()
      _current_context.active_round = false
      _setup_enemy_queue()
      _state.current = "enemies"
      return
    else:
      _state.current = "end_game"
      UI.inst.show_system_message("You've lost, plunging the world into eternal night.")
      return

  _state.current = "start_round"
  _current_context = ExecutionContext.new()
  _current_context.active_round = false
  
func _setup_enemy_queue():
  var played = GridManager.inst.get_played_tiles().filter(func(tile: Tile): return not tile.def.initiates)
  played.shuffle()
  var amount = ceili(len(played)*0.1)
  print("creating %d enemy tiles (10%% of current)" % amount)
  var spawned := 0
  for i in 1000:
    if spawned > amount or not played: break

    var spot = (played.pop_front() as Tile).get_open_neighbor()
    if spot:
      var data = enemy_tile_container.resources.pick_random()
      _enemy_queue[spot] = data
      spawned += 1
  
func _distribute_enemies(machine: CallableStateMachine, delta: float):
  if _enemy_queue:
    if _set_enemy_timer.check(delta):
      var next = _enemy_queue.keys().front()
      var tile = load("res://scenes/board/tile.tscn").instantiate()
      tile.def = _enemy_queue[next]
      
      GridManager.inst.try_place_tile(tile, next)
      
      _enemy_queue.erase(next)
  else:
    _state.current = "wait_for_accept_shop"
    
func _shop(machine: CallableStateMachine, delta: float):
  pass
  
func _begin_execution(machine: CallableStateMachine, delta: float):
  if not player_tasks.finished:
    return
  
  var tiles = GridManager.inst.get_played_tiles()
  _initiate_tiles = tiles.filter(func(tile: Tile): return tile.def.initiates)
  _current_context = ExecutionContext.new()
  _current_context.active_round = true
  _execution_order = GridManager.inst.collect_tiles_in_execution_order()
  _post_execution_order = tiles.filter(func(tile: Tile): return tile.has_post_round_effects())
  _maintain_queue(_execution_order)
  _maintain_queue(_post_execution_order)
  print("executing [pre=%d,mid=%d,post=%d]" % [ len(_pre_execution_order), len(_execution_order), len(_post_execution_order) ])
  _state.current = "execute"
  
func _maintain_queue(queue: Array):
  for tile: Tile in queue:
    tile.tree_exiting.connect(queue.erase.bind(tile), CONNECT_ONE_SHOT)
  
func _pre_execute(machine: CallableStateMachine, delta: float):
  _execute_tiles_from(
    _pre_execution_order, 
    "deal", 
    TileEffect.Event.ON_ROUND_START, 
    func(): _execution_order = GridManager.inst.collect_tiles_in_execution_order(),
    delta
  )
  
func _post_execute(machine: CallableStateMachine, delta: float):
  _execute_tiles_from(
    _post_execution_order, 
    "post_round", 
    TileEffect.Event.ON_ROUND_END,
    func(): _current_context = null,
    delta
  )
  
func _execute_turn(machine: CallableStateMachine, delta: float):
  _execute_tiles_from(
    _execution_order, 
    "post_execute", 
    TileEffect.Event.ON_ACTIVATE, 
    func(): _post_execution_order = GridManager.inst.collect_tiles_in_execution_order().filter(func(tile: Tile): return tile.has_post_round_effects()),
    delta
  )
      
func _execute_tiles_from(order: Array, next_state: String, event: TileEffect.Event, on_finished: Callable, delta: float):  
  if order:
    var next = order.pop_front()
    if is_instance_valid(next):
      _current_context.tile_execution_count += 1
      _execution_queue.push_back(next.execute(_current_context, event))
  elif _execution_queue:
    if is_instance_valid(_execution_queue.front()):
      # once it's finished executing remove it
      if not _execution_queue.front().is_executing():
        _execution_queue.pop_front()
    else:
      _execution_queue.pop_front()
  else:
    if _play_timer.check(delta):
      _state.current = next_state
      if on_finished.is_valid():
        on_finished.call()
