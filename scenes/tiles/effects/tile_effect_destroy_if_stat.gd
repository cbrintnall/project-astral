extends TileEffect
class_name TileEffectDestroyIfStat

@export var stat: StatDef
@export var value := 0

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "If %s hits %d (%d/%d), destroy this tile." % [stat.name, value, effect_ctx.tile.stat.get_value(stat), value]
  
func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  if roundi(effect_ctx.tile.stat.get_value(stat)) == value:
    effect_ctx.tile.destroy()
