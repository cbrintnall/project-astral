extends Node
class_name GameManager

static var inst: GameManager

@export var camera: Camera3D
@export var selection_svp: SubViewport

var current_score := 0
var required_score: int:
  get:
    return Constants.REQUIRED_SCORES[mini(cycle, len(Constants.REQUIRED_SCORES)-1)]

var active_execution: ExecutionContext:
  get:
    return _current_context

var cycle := 0
var turn := 0

var player_tasks := TaskGroup.new()

var _state := CallableStateMachine.new()
var _deal_timer := BetterTimer.new(0.1)

var _initiate_tiles := []
var _current_context: ExecutionContext
var _execution_order := []
var _pre_execution_order := []
var _post_execution_order := []

var _sound_counter := 0.0
var _reset_sound_timer := BetterTimer.new(1.0)

func do_receive_points_fx():
  _sound_counter += 0.01
  
  AudioManager3d.play({
    "stream": preload("res://audio/Light Drone Sound (button hover) 9.wav"),
    "pitch_additional": _sound_counter,
    "debounce": 0.05
  })
  
  _reset_sound_timer.reset()

func try_execute_turn():
  _state.current = "begin_execution"
  TileHand.inst.discard_hand()

func _unhandled_input(event: InputEvent) -> void:
  if event.is_action_pressed("toggle_debug"):
    DebugDraw2D.debug_enabled = not DebugDraw2D.debug_enabled

func _ready() -> void:
  DebugDraw2D.debug_enabled = false
  
  inst = self
  add_child(_state)
  add_child(player_tasks)
  
  _state.register("deal", _deal)
  _state.register("wait_for_player", _wait_for_player)
  _state.register("begin_execution", _begin_execution)
  _state.register("pre_execute", _pre_execute)
  _state.register("execute", _execute_turn)
  _state.register("post_execute", _post_execute)
  _state.register("post_round", _post_round)
  
  selection_svp.world_3d = get_viewport().find_world_3d()
  
  _state.state_changed.connect(
    func(state):
      print("game state changed: %s" % state)
  )
  
  await Utils.wait_until(func(): return GridManager.inst != null)
  
  GridManager.inst.board_changed.connect(_on_board_changed)
  
  var start_tile = load("res://scenes/board/tile.tscn").instantiate()
  start_tile.def = load("res://data/tiles/tile_source_tile.tres")
  assert(GridManager.inst.try_place_tile(start_tile, Vector3i.ZERO), "This should never fail")
  GridManager.inst.center_tile = start_tile
  BoardCamera.inst.try_set_focus(GridManager.inst.map_to_global(Vector3i.ZERO))
  var start_mesh: MeshInstance3D = NodeUtils.find_child_with_predicate(start_tile, func(node): return node is MeshInstance3D)
  start_mesh.material_override = preload("res://materials/material_debug.tres")
  
func _on_board_changed():
  _execution_order = GridManager.inst.collect_tiles_in_execution_order()
  _pre_execution_order = _execution_order.filter(func(tile: Tile): return tile.has_pre_round_effects())
  _post_execution_order = _execution_order.filter(func(tile: Tile): return tile.has_post_round_effects())
  
func _process(delta: float) -> void:
  if _reset_sound_timer.check(delta):
    _sound_counter = 0.0
  
func _deal(machine: CallableStateMachine, delta: float):
  turn += 1
  TileHand.inst.distribute_hand()
  _state.current = "wait_for_player"

func _wait_for_player(machine: CallableStateMachine, delta: float):
  pass

func _post_round(machine: CallableStateMachine, delta: float):
  if turn >= Constants.TURNS_PER_SCORE:
    if current_score >= required_score:
      print("beat cycle!!!!")
      if cycle >= len(Constants.REQUIRED_SCORES)-1:
        print("YOU BEAT THE GAME YIPPPEEEE")
        get_tree().quit()
        return
      cycle += 1
      turn = 0
    else:
      print("you lost!!!!")
      get_tree().quit()

  _state.current = "deal"
  _current_context = ExecutionContext.new()
  _current_context.active_round = false
  
func _begin_execution(machine: CallableStateMachine, delta: float):
  if not player_tasks.finished:
    return
  
  var tiles = GridManager.inst.get_played_tiles()
  _initiate_tiles = tiles.filter(func(tile: Tile): return tile.def.initiates)
  _current_context = ExecutionContext.new()
  _current_context.active_round = true
  _execution_order = GridManager.inst.collect_tiles_in_execution_order()
  _pre_execution_order = _execution_order.filter(func(tile: Tile): return tile.has_pre_round_effects())
  _post_execution_order = _execution_order.filter(func(tile: Tile): return tile.has_post_round_effects())
  print("executing [pre=%d,mid=%d,post=%d]" % [ len(_pre_execution_order), len(_execution_order), len(_post_execution_order) ])
  _state.current = "pre_execute"
  
func _pre_execute(machine: CallableStateMachine, delta: float):
  _execute_tiles_from(
    _pre_execution_order, 
    "execute", 
    TileEffect.Event.ON_ROUND_START, 
    func(): _execution_order = GridManager.inst.collect_tiles_in_execution_order()
  )
  
func _post_execute(machine: CallableStateMachine, delta: float):
  _execute_tiles_from(
    _post_execution_order, 
    "post_round", 
    TileEffect.Event.ON_ROUND_END,
    func(): _current_context = null
  )
  
func _execute_turn(machine: CallableStateMachine, delta: float):
  _execute_tiles_from(
    _execution_order, 
    "post_execute", 
    TileEffect.Event.ON_ACTIVATE, 
    func(): _post_execution_order = GridManager.inst.collect_tiles_in_execution_order().filter(func(tile: Tile): return tile.has_post_round_effects())
  )
      
func _execute_tiles_from(order: Array, next_state: String, event: TileEffect.Event, on_finished: Callable):
  if _current_context.current_tile:
    var loc = GridManager.inst.get_tile_loc(_current_context.current_tile)
    if loc != Vector3i.MIN:
      BoardCamera.inst.try_set_focus(loc)
  
  if _current_context.current_tile == null:
    if order:
      var next = order.pop_front()
      if is_instance_valid(next):
        _current_context.current_tile = next
        _current_context.current_tile.execute(_current_context, event)
    else:
      _state.current = next_state
      if on_finished.is_valid():
        on_finished.call()
