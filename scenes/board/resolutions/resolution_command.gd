@abstract
extends Command
class_name ResolutionCommand

enum ResolutionState {
  WAITING,
  CAN_EXECUTE,
  SHOULD_DEFER,
  FAILED
}

var context: ExecutionContext
var state := ResolutionState.WAITING

func _init(ctx: ExecutionContext):
  context = ctx

@abstract func cleanup()
@abstract func check()

func reset():
  state = ResolutionState.WAITING

func deadlock():
  pass
