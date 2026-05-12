extends Node
class_name TileExecutor

var tiles := []
var event: TileEffect.Event
var on_finish: Callable

var _execution_state := CallableStateMachine.new()
var _context := ExecutionContext.new()
var _end_timer := BetterTimer.new(1.0)

var _current_task: Task
var _resolution_queue := []

var _remaining := []

func start():
  _execution_state.current = "start"
  _context.active_round = true

func _ready() -> void:
  add_child(_execution_state)

  _execution_state.register("idle", CallableStateMachine.noop)
  _execution_state.register("start", _start)
  _execution_state.register("execute", _process_tiles)
  #_execution_state.register("resolve", _resolve_tiles)

func _start(machine: CallableStateMachine, _delta: float):
  machine.current = "execute"
  
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
    _remaining.push_back(queue)
  elif _remaining and _remaining.front().finished:
    _remaining.pop_front().queue_free()
    
  if not tiles and not _remaining:
    if _end_timer.check(delta):
      if on_finish.is_valid():
        on_finish.call()
        queue_free()

#func _resolve_tiles(machine: CallableStateMachine, delta: float):
  #if _resolution_queue:
    #var next = _resolution_queue.pop_front()
    #if is_instance_valid(next):
      #_context.tile_execution_count += 1
      #_execution_queue.push_back(next.execute(_context, event))
  #elif _execution_queue:
    #if is_instance_valid(_execution_queue.front()):
      ## once it's finished executing remove it
      #if not _execution_queue.front().is_executing():
        #_execution_queue.pop_front()
    #else:
      #_execution_queue.pop_front()
  #else:
    #if _end_timer.check(delta):
      #if on_finish.is_valid():
        #on_finish.call()
        #queue_free()
