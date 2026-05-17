extends TileEffect
class_name TileEffectGiveMoney

@export var amount := 1.0

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  var matching = main_target.get_target(effect_ctx)
  return "Gives %+.1f money per matching tiles. (%d)" % [amount,len(matching)]
  
func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  GameManager.inst.money += roundi(amount*len(main_target.get_target(effect_ctx)))
