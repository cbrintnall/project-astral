extends TileEffect
class_name TileEffectPointsForStats

@export var stat: StatDef
@export var provider: StatProviderDef
@export var point_multiplier := 1.0

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  pass
  
func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  pass
