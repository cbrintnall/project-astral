@abstract
extends Command
class_name ResolutionCommand

var context: ExecutionContext

func _init(ctx: ExecutionContext):
  context = ctx

@abstract func cleanup()
@abstract func check() -> bool

func run():
  if check():
    await execute()
  else:
    await undo()
