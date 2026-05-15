extends Node
class_name ResolutionHandler

signal finished

var context := ExecutionContext.new()

var _state := CallableStateMachine.new()
var _remaining_resolutions := TaskGroup.new()

var _remaining_cleanup_resolutions := []
var _resolution_cleanup := TaskGroup.new()

func start():
  _state.current = "resolving"

func _ready() -> void:
  add_child(_state)
  
  _state.register("waiting", CallableStateMachine.noop)
  _state.register("resolving", _resolve)
  
func _resolve(_machine: CallableStateMachine, _delta: float):
  if _remaining_resolutions.finished:
    if context.resolutions:
      # restart execution in case resolution itself pushes more resolutions
      var next_group: Array = context.resolutions.pop_front()
      
      if not next_group:
        return
      
      context.start_execution()
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
        context.resolutions.push_front(deferrals)
    elif _remaining_cleanup_resolutions:
      _resolution_cleanup.run(_remaining_cleanup_resolutions.pop_front().cleanup)
    elif _resolution_cleanup.finished:
      finished.emit()
      queue_free()
