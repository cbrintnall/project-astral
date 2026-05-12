extends Node
class_name TileExecutor

var tiles := []
var event: TileEffect.Event
var on_finish: Callable

var _execution_state := CallableStateMachine.new()
var _context := ExecutionContext.new()
var _execution_queue := []
var _end_timer := BetterTimer.new(1.0)

func start():
  _execution_state.current = "start"
  _context.active_round = true

func _ready() -> void:
  add_child(_execution_state)
  
  _execution_state.register("idle", CallableStateMachine.noop)
  _execution_state.register("start", _start)
  _execution_state.register("execute", _process_tiles)

func _start(machine: CallableStateMachine, _delta: float):
  machine.current = "execute"
  
func _process_tiles(machine: CallableStateMachine, delta: float):
  if tiles:
    var next = tiles.pop_front()
    if is_instance_valid(next):
      _context.tile_execution_count += 1
      _execution_queue.push_back(next.execute(_context, event))
  elif _execution_queue:
    if is_instance_valid(_execution_queue.front()):
      # once it's finished executing remove it
      if not _execution_queue.front().is_executing():
        _execution_queue.pop_front()
    else:
      _execution_queue.pop_front()
  else:
    if _end_timer.check(delta):
      if on_finish.is_valid():
        on_finish.call()
        queue_free()
