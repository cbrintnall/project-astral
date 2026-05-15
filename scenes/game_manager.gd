extends Node
class_name GameManager

static var inst: GameManager
static var debug := false
static var game_closing := false

signal points_fx

@export var camera: Camera3D
@export var selection_svp: SubViewport
@export var enemy_tile_container: EnemyTileContainer

@export var light: DirectionalLight3D

@export var default_cycle_tasks: Array[CycleEffect] = []
@export var varied_cycle_tasks: Array[CycleEffect] = []

@export var default_turn_tasks: Array[CycleEffect] = []
@export var varied_turn_tasks: Array[CycleEffect] = []

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
    
var upcoming_cycle_tasks: Array:
  get:
    return _next_cycle_tasks
    
var current_turn_tasks: Array:
  get:
    return _current_turn_modifiers

var won := false

var _background_color := Color.from_string("#272744", Color.WHITE)

var _state := CallableStateMachine.new()
var _deal_timer := BetterTimer.new(0.1)

var _initiate_tiles := []
var _current_context: ExecutionContext

var _sound_counter := 0.0
var _reset_sound_timer := BetterTimer.new(1.0)

var _executor_queue := TaskQueue.new()
var _cycle_task_runner := TaskQueue.new()
var _next_cycle_tasks := []
var _current_turn_modifiers := []

func start_execution(effects: Array, event: TileEffect.Event):
  pass

func enter_shop():
  assert(current_state == "wait_for_accept_shop")
  _state.current = "shop"
  ShopManager.inst.enter()

func leave_shop():
  assert(current_state == "shop")
  _state.current = "start_round"
  BoardCamera.inst.try_set_focus(Vector3.ZERO)

func try_execute_turn():
  _state.current = "begin_execution"
  TileHand.inst.discard_hand()

func _notification(what: int) -> void:
  if what == NOTIFICATION_WM_CLOSE_REQUEST:
    game_closing = true

func _ready() -> void:
  Console.pause_enabled = true

  _current_context = ExecutionContext.new()
  
  inst = self
  add_child(_state)
  add_child(cycle_tasks)
  add_child(_cycle_task_runner)
  add_child(_executor_queue)
  
  _state.register("start_round", _start_round)
  _state.register("deal", _deal)
  _state.register("wait_for_player", CallableStateMachine.noop)
  _state.register("begin_execution", _begin_execution)
  _state.register("pre_execute", CallableStateMachine.noop)
  _state.register("execute", CallableStateMachine.noop)
  _state.register("post_execute", CallableStateMachine.noop)
  _state.register("post_round", _post_round)
  _state.register("run_end_cycle", CallableStateMachine.noop)
  _state.register("shop", CallableStateMachine.noop)
  _state.register("start_cycle_events", _start_cycle_events)
  _state.register("wait_for_accept_shop", CallableStateMachine.noop)
  _state.register("end_game", _end_game)
  
  _state.state_changed.connect(func(state): print("game state changed: %s" % state))
  
  await Utils.wait_until(func(): return GridManager.inst != null and GridManager.inst.is_node_ready())
  
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
      GameManager.debug = not GameManager.debug
  )
  
func _process(delta: float) -> void:
  DebugDraw2D.debug_enabled = GameManager.debug
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
  
  # if start of new cycle..
  if turn == 0:
    # TODO: add varied tasks here as well
    _next_cycle_tasks.append_array(default_cycle_tasks)
    _current_turn_modifiers.append_array(default_turn_tasks)
  
  turn += 1
  
  BoardCamera.inst.map_size = GridManager.inst.size
  BoardCamera.inst.map_root = Vector3.ZERO
  
  _setup_executor(
    GridManager.inst.get_played_tiles(),
    TileEffect.Event.ON_ROUND_START,
    func():
      if Constants.CHOOSE_TILES_EACH_ROUND:
        UI.inst.choose_tiles.setup()
      # TODO: add varied tasks here as well
      for task: CycleEffect in _current_turn_modifiers:
        cycle_tasks.register(task.on_cycle_start)
      cycle_tasks.just_finished.connect(func(): _state.current = "deal", CONNECT_ONE_SHOT)
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
      point_source.current = 0
      turn = 0
      _current_context = ExecutionContext.new()
      _current_context.active_round = false
      while _next_cycle_tasks:
        cycle_tasks.register(_next_cycle_tasks.pop_front().on_cycle_start)
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
  _initiate_tiles = tiles.filter(func(tile: Tile): return tile.def != null and tile.def.initiates)
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
  var next_executor := TileExecutor.new()
  add_child(next_executor)
  for tile: Tile in tiles:
    next_executor.register_group(tile.get_effect_context(), tile.get_effects())
  next_executor.event = event
  next_executor.on_finish = on_finish
  
  _executor_queue.register(
    func():
      next_executor.start()
      await next_executor.finished   
  )
