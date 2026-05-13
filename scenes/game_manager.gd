extends Node
class_name GameManager

static var inst: GameManager

signal points_fx

@export var camera: Camera3D
@export var selection_svp: SubViewport
@export var enemy_tile_container: EnemyTileContainer

@export var light: DirectionalLight3D

@export var default_cycle_tasks: Array[CycleEffect] = []
@export var varied_cycle_tasks: Array[CycleEffect] = []

var current_score: int:
  get:
    return point_source.current

var required_score: int:
  get:
    return Constants.REQUIRED_SCORES[mini(cycle, len(Constants.REQUIRED_SCORES)-1)]

var active_execution: ExecutionContext:
  get:
    return _current_context

var cycle := 0
var turn := 0

var point_source := PointSource.new()
var player_tasks := TaskGroup.new()
var cycle_tasks := TaskQueue.new()
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

var _sound_counter := 0.0
var _reset_sound_timer := BetterTimer.new(1.0)

var _executor: TileExecutor

func enter_shop():
  assert(current_state == "wait_for_accept_shop")
  _state.current = "shop"
  ShopManager.inst.enter()

func leave_shop():
  assert(current_state == "shop")
  _state.current = "start_round"
  BoardCamera.inst.try_set_focus(Vector3.ZERO)

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
  point_source.fx_finished.connect(do_receive_points_fx)
  
  inst = self
  add_child(_state)
  add_child(cycle_tasks)
  
  _state.register("start_round", _start_round)
  _state.register("deal", _deal)
  _state.register("wait_for_player", CallableStateMachine.noop)
  _state.register("begin_execution", _begin_execution)
  _state.register("pre_execute", CallableStateMachine.noop)
  _state.register("execute", CallableStateMachine.noop)
  _state.register("post_execute", CallableStateMachine.noop)
  _state.register("post_round", _post_round)
  _state.register("shop", CallableStateMachine.noop)
  _state.register("start_cycle_events", _start_cycle_events)
  _state.register("wait_for_accept_shop", CallableStateMachine.noop)
  _state.register("end_game", _end_game)
  
  _state.state_changed.connect(
    func(state):
      print("game state changed: %s" % state)
  )
  
  await Utils.wait_until(func(): return GridManager.inst != null)
  
  var start_tile = load("res://scenes/board/tile.tscn").instantiate()
  start_tile.def = load("res://data/tiles/tile_source_tile.tres")
  assert(GridManager.inst.try_place_tile(start_tile, Vector3i.ZERO), "This should never fail")
  BoardCamera.inst.try_set_focus(GridManager.inst.map_to_global(Vector3i.ZERO))
  var start_mesh: MeshInstance3D = NodeUtils.find_child_with_predicate(start_tile, func(node): return node is MeshInstance3D)
  if start_mesh:
    start_mesh.queue_free()
  var eos = load("res://assets/blender/objects/eos.tscn").instantiate()
  start_tile.add_child(eos)
  point_source.target_point = NodeUtils.find_child_with_predicate(eos, func(node: Node): return node.name == "EosHand").global_position
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
  var hovered_ui = get_viewport().gui_get_hovered_control().get_path() if get_viewport().gui_get_hovered_control() else "none"
  DebugDraw2D.begin_text_group("-=-=-=- Game -=-=-=-")
  DebugDraw2D.set_text("hovered control", hovered_ui)
  DebugDraw2D.end_text_group()
  
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
  RenderingServer.global_shader_parameter_set("grid_root", Vector3.ZERO)
  turn += 1
  
  BoardCamera.inst.map_size = GridManager.inst.size
  BoardCamera.inst.map_root = Vector3.ZERO
  
  _setup_executor(
    GridManager.inst.get_played_tiles(),
    TileEffect.Event.ON_ROUND_START,
    func():
      UI.inst.choose_tiles.setup()
      _state.current = "deal"
  )
  
  _state.current = "pre_execute"
  
func _deal(machine: CallableStateMachine, delta: float):
  if TileHand.inst.get_tile_count() >= Constants.DEFAULT_HAND_SIZE:
    _state.current = "wait_for_player"
    return
  
  if _deal_timer.check(delta):
    var next = HandManager.inst.get_next_from_hand()
    TileHand.inst.add_to_hand(next)

func _start_cycle_events(machine: CallableStateMachine, _delta: float):
  if cycle_tasks.finished:
    machine.current = "wait_for_accept_shop"

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
      var chosen_fx = []
      chosen_fx.append_array(default_cycle_tasks)
      # TODO: add varied tasks here as well
      for task: CycleEffect in chosen_fx:
        cycle_tasks.register(task.on_cycle_start)
      _state.current = "start_cycle_events"
      return
    else:
      _state.current = "end_game"
      UI.inst.show_system_message("You've lost, plunging the world into eternal night.")
      return

  _state.current = "start_round"
  _current_context = ExecutionContext.new()
  _current_context.active_round = false
  
func _begin_execution(machine: CallableStateMachine, delta: float):
  if not player_tasks.finished:
    return
  
  var tiles = GridManager.inst.get_played_tiles()
  _initiate_tiles = tiles.filter(func(tile: Tile): return tile.def.initiates)
  _setup_executor(
    GridManager.inst.collect_tiles_in_execution_order(),
    TileEffect.Event.ON_ACTIVATE,
    func():
      _setup_executor(
        GridManager.inst.collect_tiles_in_execution_order(),
        TileEffect.Event.ON_ROUND_END,
        func():
          _state.current = "post_round"
      )
      _state.current = "post_execute"
  )

  _state.current = "execute"
  
func _setup_executor(tiles: Array, event: TileEffect.Event, on_finish: Callable):
  if _executor and _executor != null:
    print("setting up new tile executor, but last one is still around (%s)" % _executor.get_path())
  
  _executor = TileExecutor.new()
  _executor.tiles = tiles
  _executor.event = event
  _executor.on_finish = on_finish
  add_child(_executor)
  _executor.start()
