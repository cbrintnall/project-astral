extends TileEffect
class_name TileEffectModifyStat

@export var stat: StatDef
@export var provider: StatProviderDef

@export var description_verbiage := "Set"

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "%s %s by %s." % [ description_verbiage, stat.name, StatProviderDef.get_value_as_format(provider.amount) ]

func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  effect_ctx.tile.stat.add_provider(stat, provider)
