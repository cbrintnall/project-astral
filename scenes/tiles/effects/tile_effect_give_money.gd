extends TileEffect
class_name TileEffectGiveMoney

@export var amount := 1

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "Gives %d money." % amount
  
func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  GameManager.inst.money += amount
