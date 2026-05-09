extends TileEffect
class_name TileEffectDestroyFirstEncountered

@export var amount_destroyed := 1

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "Destroys the first %d destruction tiles it encounters after itself." % amount_destroyed
  
func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  await get_tree().create_timer(1.0).timeout
  print("TODO :)")
