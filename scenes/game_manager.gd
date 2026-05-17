extends Node
class_name GameManager

static var inst: GameManager
static var debug := false
static var game_closing := false
static var played_tutorial := false

signal points_fx
signal executor_queued(exec: TileExecutor)

@export var camera: Camera3D
@export var selection_svp: SubViewport
@export var enemy_tile_container: EnemyTileContainer

@export var light: DirectionalLight3D

@export var default_cycle_tasks: Array[TileEffect] = []
@export var varied_cycle_tasks: Array[TileEffect] = []

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
var total_turns := 0

var point_source := PointSource.new()
var player_tasks := TaskGroup.new()
var cycle_tasks := TaskQueue.new()
var money := Constants.START_MONEY

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
var _task_binds := {}
var _imbuement_cooldowns = {}
var _return_from_shop_state := ""

func on_tutorial_finished():
  played_tutorial = true
  _state.current = "start_round"

func get_remaining_cooldown_for_imbuement(imbuement: ImbuementDef) -> int:
  if _imbuement_cooldowns.has(imbuement):
    return ((total_turns-_imbuement_cooldowns.get(imbuement))-imbuement.turn_cooldown)
  return 0

func try_use_imbuement(imbuement: ImbuementDef, pos: Vector3i) -> bool:
  if get_remaining_cooldown_for_imbuement(imbuement) < 0:
    return false
    
  var ctx := EffectContext.from_override(pos)
  
  var exec := GameManager.inst.queue_execution(
    imbuement.effects,
    TileEffect.Event.CUSTOM,
    ctx
  )
  
  exec.ignore_event = true
  _imbuement_cooldowns[imbuement] = total_turns
    
  return true

func queue_execution(effects: Array, event: TileEffect.Event, ctx := EffectContext.new(), on_finish := Callable()) -> TileExecutor:
  var next_executor := TileExecutor.new()
  add_child(next_executor)
  next_executor.register_group(ctx, effects)
  next_executor.event = event
  next_executor.on_finish = on_finish
  
  _executor_queue.register(
    func():
      next_executor.start()
      await next_executor.finished   
  )
  
  executor_queued.emit(next_executor)
  _check_for_events(next_executor, _next_cycle_tasks)
  
  return next_executor
  
func queue_tile_execution(tiles: Array, event: TileEffect.Event, on_finish := Callable()) -> TileExecutor:
  var next_executor := _setup_executor(tiles, event, on_finish)
  return next_executor

func enter_shop(next_state: String):
  _return_from_shop_state = next_state
  _state.current = "shop"
  ShopManager.inst.enter()

func leave_shop():
  assert(current_state == "shop")
  _state.current = _return_from_shop_state
  BoardCamera.inst.map_size = GridManager.inst.size
  BoardCamera.inst.map_root = Vector3.ZERO
  BoardCamera.inst.try_set_focus(Vector3.ZERO)
  RenderingServer.global_shader_parameter_set("grid_root", Vector3.ZERO)

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
  
  _state.register("initializing", CallableStateMachine.noop)
  _state.register("tutorial", CallableStateMachine.noop)
  _state.register("waiting_for_execution", CallableStateMachine.noop)
  _state.register("start_round", _start_round)
  _state.register("deal", _deal)
  _state.register("wait_for_player", CallableStateMachine.noop)
  _state.register("begin_execution", _begin_execution)
  _state.register("execute", CallableStateMachine.noop)
  _state.register("post_execute", CallableStateMachine.noop)
  _state.register("post_round", _post_round)
  _state.register("run_end_cycle", CallableStateMachine.noop)
  _state.register("shop", CallableStateMachine.noop)
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
  
  Console.add_command(
    "shop",
    func():
      enter_shop(_state.current)
  )
  
  Console.add_command(
    "money",
    func(amt: String):
      money += int(amt),
    ["amt"]
  )
  
  Console.add_command(
    "defense",
    func():
      GridManager.inst.get_played_tiles().pick_random().defense += 5
  )
  
  Console.add_command(
    "damage",
    func():
      var tile: Tile = GridManager.inst.get_played_tiles().pick_random()
      tile.do_chip_damage(6)
  )
  
  await Utils.wait_until(func(): return HandManager.inst.is_node_ready())

  BoardCamera.inst.map_size = GridManager.inst.size
  BoardCamera.inst.map_root = Vector3.ZERO

  if not played_tutorial:
    _state.current = "tutorial"
  else:
    _state.current = "start_round"
  
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
  
func _handle_effect(exec: TileExecutor, effect: TileEffect):
  if not effect.event == exec.event: return
  
  exec.register_group(EffectContext.new(), [effect])
  
func _start_round(machine: CallableStateMachine, delta: float):
  RenderingServer.global_shader_parameter_set("grid_root", Vector3.ZERO)
  
  # if start of new cycle..
  if turn == 0:
    # TODO: add varied tasks here as well
    _next_cycle_tasks = []
    _next_cycle_tasks.append_array(default_cycle_tasks)
    var varied = mini(Constants.EVENTS_PER_CYCLE[mini(cycle, len(Constants.EVENTS_PER_CYCLE)-1)], len(varied_cycle_tasks))
    var possible = varied_cycle_tasks.duplicate()
    possible.shuffle()
    for i in varied:
      _next_cycle_tasks.push_back(possible.pop_front())
  
  turn += 1
  total_turns += 1
  
  BoardCamera.inst.map_size = GridManager.inst.size
  BoardCamera.inst.map_root = Vector3.ZERO
  
  _setup_executor(
    GridManager.inst.get_played_tiles(),
    TileEffect.Event.ON_ROUND_START,
    func():
      if Constants.CHOOSE_TILES_EACH_ROUND:
        UI.inst.choose_tiles.setup()
      
      if turn == 1:
        _state.current = "wait_for_accept_shop"
      else:
        _state.current = "deal"
  )
  
  _state.current = "waiting_for_execution"
  
func _deal(machine: CallableStateMachine, delta: float):
  if TileHand.inst.get_tile_count() >= mini(Constants.DEFAULT_HAND_SIZE, len(HandManager.inst.all_tiles)):
    _state.current = "wait_for_player"
    return
  
  if _deal_timer.check(delta):
    var next = HandManager.inst.get_next_from_hand()
    if next:
      TileHand.inst.add_to_hand(next)

func _post_round(machine: CallableStateMachine, delta: float):
  if current_score >= required_score:
    money += 1
  
  if turn >= Constants.TURNS_PER_SCORE:
    if current_score >= required_score:
      if cycle >= len(Constants.REQUIRED_SCORES)-1:
        won = true
        _state.current = "end_game"
        UI.inst.show_system_message("You've won, pushing back Nyx's power.")
        return
      
      UI.inst.show_system_message("Begin Cycle")
      cycle += 1
      point_source.current = 0
      turn = 0
      _current_context = ExecutionContext.new()
      _current_context.active_round = false
      queue_execution(
        _next_cycle_tasks,
        TileEffect.Event.ON_CYCLE_START,
        EffectContext.new()
      )
      return
    else:
      _state.current = "end_game"
      UI.inst.show_system_message("Nyx has overcome your light.")
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
  
func _check_for_events(executor: TileExecutor, effects: Array):
  var ctx := EffectContext.new()
  
  # NOTE: Trigger only off player placed tiles, otherwise this gets chaotic,
  # this isn't long term but is just a design patch for now
  if executor.event == TileEffect.Event.ON_PLACE:
    if executor.execution.initiator.faction == Tile.Faction.ENEMY:
      print("executor place event was enemy, skipping")
      return
  
  executor.register_group(
    ctx,
    effects.filter(func(fx: TileEffect): return fx.event == executor.event) 
  )
  
func _setup_executor(tiles: Array, event: TileEffect.Event, on_finish: Callable) -> TileExecutor:
  var next_executor := TileExecutor.new()
  add_child(next_executor)
  for tile: Tile in tiles:
    next_executor.register_group(tile.get_effect_context(), tile.get_effects())
  next_executor.event = event
  next_executor.on_finish = on_finish
  
  # NOTE: temp workaround, this should be set outside this but w/e
  if len(tiles) == 1 and event == TileEffect.Event.ON_PLACE:
    next_executor.execution.set_initiator(tiles.front())
  
  # emit before register, in-case we want to register more
  executor_queued.emit(next_executor)
  _check_for_events(next_executor, _next_cycle_tasks)
  
  _executor_queue.register(
    func():
      next_executor.start()
      await next_executor.finished   
  )
  return next_executor
