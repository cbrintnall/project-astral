extends Node
class_name TileExecutor

var tiles := []
var resolutions := []

var event: TileEffect.Event
var on_finish: Callable

var _execution_state := CallableStateMachine.new()
var _context := ExecutionContext.new()
var _end_timer := BetterTimer.new(1.0)

var _remaining := []
var _remaining_resolutions := TaskGroup.new()

func start():
  _execution_state.current = "start"
  _context.active_round = true

func _ready() -> void:
  add_child(_execution_state)

  _execution_state.register("idle", CallableStateMachine.noop)
  _execution_state.register("start", _start)
  _execution_state.register("execute", _process_tiles)
  _execution_state.register("resolve", _resolve_tiles)

func _start(machine: CallableStateMachine, _delta: float):
  machine.current = "execute"
  _context.start_execution()
  
func _process_tiles(machine: CallableStateMachine, delta: float):
  if tiles:
    var next: Tile = tiles.pop_front()
    
    if not is_instance_valid(next): return
    
    var fx = next.get_effects().filter(func(effect: TileEffect): return effect.event == event)
    
    if not fx: return
    
    _context.tile_execution_count += 1
    var ctx: EffectContext = EffectContext.new()
    ctx.tile = next
    next.do_execute_fx(_context)
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
    
  if not tiles and not _remaining:
    machine.current = "resolve"

func _resolve_tiles(machine: CallableStateMachine, delta: float):
  if _remaining_resolutions.finished:
    if _context.resolutions:
      # restart execution in case resolution itself pushes more resolutions
      var next_group: Array = _context.resolutions.pop_front()
      if next_group:
        _context.start_execution()
        for res: ResolutionCommand in next_group:
          _remaining_resolutions.run(res.run)
    else:
      if _end_timer.check(delta):
        if on_finish.is_valid():
          on_finish.call()
        queue_free()
