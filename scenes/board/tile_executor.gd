extends Node
class_name TileExecutor

static var long_exec_time := 30.0

signal finished

var effect_groups := []
var resolutions := []
var ignore_event := false

var event: TileEffect.Event
var on_finish: Callable

var execution: ExecutionContext:
  get:
    return _context

var _execution_state := CallableStateMachine.new()
var _context := ExecutionContext.new()

var _remaining := []
var _remaining_resolutions := TaskGroup.new()

var _remaining_cleanup_resolutions := []
var _resolution_cleanup := TaskGroup.new()

var _time := 0.0

func give_execution_collision_data(data: TileCollisionContext):
  _context.collision_data = data

func register_group(ctx: EffectContext, effects: Array):
  if _execution_state.current != "idle":
    push_error("Tried to register effect execution while executor already running.. (%s)" % get_path())
    return
    
  var effect_exec_ctx := EffectExecutionContext.new()
  effect_exec_ctx.effect_ctx = ctx
  effect_exec_ctx.effects = effects
    
  effect_groups.push_back(effect_exec_ctx)

func start():
  _execution_state.current = "start"
  _context.active_round = true

func _ready() -> void:
  add_child(_execution_state)

  _execution_state.register("idle", CallableStateMachine.noop)
  _execution_state.register("start", _start)
  _execution_state.register("execute", _process_effects)
  _execution_state.register("resolve", _resolve_tiles)
  
func _process(_delta: float) -> void:
  DebugDraw2D.begin_text_group("%s execution" % get_path())
  DebugDraw2D.set_text("time", _time)
  DebugDraw2D.set_text("executing", len(effect_groups))
  DebugDraw2D.set_text("resolving", len(_context.resolutions))
  DebugDraw2D.end_text_group()
  
  if GameManager.debug and _time > long_exec_time:
    breakpoint

func _start(machine: CallableStateMachine, _delta: float):
  machine.current = "execute"
  _context.start_execution()
  
func _process_effects(machine: CallableStateMachine, delta: float):
  _time += delta
  if effect_groups:
    var next: EffectExecutionContext = effect_groups.pop_front()
    var fx = next.effects.filter(func(effect: TileEffect): return effect.event == event or ignore_event)
    
    if not fx: return
    
    _context.tile_execution_count += 1
    var ctx: EffectContext = next.effect_ctx
    var queue := TaskQueue.new()
    add_child(queue)
    for effect: TileEffect in fx:
      queue.register(effect.run.bind(ctx, _context))
    _remaining.push_back({
      "tile": next,
      "queue": queue,
      "effects": fx,
      "context": ctx
    })
  elif _remaining and _remaining.front()["queue"].finished:
    var payload: Dictionary = _remaining.pop_front()
    payload["queue"].queue_free()
    payload.erase("queue")
    
  if not effect_groups and not _remaining:
    machine.current = "resolve"

func _resolve_tiles(machine: CallableStateMachine, delta: float):
  _time += delta
  if _remaining_resolutions.finished:
    if _context.resolutions:
      # restart execution in case resolution itself pushes more resolutions
      var next_group: Array = _context.resolutions.pop_front()
      
      if not next_group:
        return
      
      _context.start_execution()
      for command: ResolutionCommand in next_group:
        command.check()
      var deadlocked = next_group.all(func(command: ResolutionCommand): return command.state == ResolutionCommand.ResolutionState.SHOULD_DEFER)
      if deadlocked:
        for command: ResolutionCommand in next_group:
          _remaining_resolutions.run(command.deadlock)
      else:
        var deferrals = []
        for command: ResolutionCommand in next_group:
          match command.state:
            ResolutionCommand.ResolutionState.FAILED:
              _remaining_resolutions.run(command.undo)
              _remaining_cleanup_resolutions.push_back(command)
            ResolutionCommand.ResolutionState.CAN_EXECUTE:
              _remaining_resolutions.run(command.execute)
              _remaining_cleanup_resolutions.push_back(command)
            ResolutionCommand.ResolutionState.SHOULD_DEFER:
              deferrals.push_back(command)
              command.reset()
        _context.resolutions.push_front(deferrals)
    elif _remaining_cleanup_resolutions:
      _resolution_cleanup.run(_remaining_cleanup_resolutions.pop_front().cleanup)
    elif _resolution_cleanup.finished:
      if on_finish.is_valid():
        on_finish.call()
      finished.emit()
      queue_free()
