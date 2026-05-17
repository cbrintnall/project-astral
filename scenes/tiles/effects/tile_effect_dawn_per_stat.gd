extends TileEffect
class_name TileEffectDawnPerStat

@export var stat: StatDef
@export var amount_per := 1

func get_tile_baseline_points(effect_ctx: EffectContext) -> int:
  return amount_per*roundi(effect_ctx.tile.stat.get_value(stat))

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  var amount_stat = roundi(effect_ctx.tile.stat.get_value(stat) if effect_ctx.tile else 0.0)
  return "Gives [color=#c69fa5]%d[/color] dawn per stack of %s (%d)" % [ amount_per, stat.name, get_tile_baseline_points(effect_ctx) ]

func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  _reward_points(effect_ctx, get_tile_baseline_points(effect_ctx))
