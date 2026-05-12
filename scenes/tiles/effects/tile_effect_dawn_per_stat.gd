extends TileEffect
class_name TileEffectDawnPerStat

@export var stat: StatDef
@export var amount_per := 1

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  var amount_stat = roundi(effect_ctx.tile.stat.get_value(stat) if effect_ctx.tile else 0.0)
  return "Gives %d per stack of %s (%d)" % [ amount_per, stat.name, _get_total_points(effect_ctx, amount_per*amount_stat) ]

func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  _reward_points(effect_ctx, amount_per*roundi(effect_ctx.tile.stat.get_value(stat)))
