extends TileEffect
class_name TileEffectModifyStat

@export var stat: StatDef
@export var provider: StatProviderDef

@export var description_verbiage := "Set"

func _get_targets(ctx: EffectContext):
  return main_target.get_target(ctx)

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "%s %s by %s %s." % [ description_verbiage, stat.name, StatProviderDef.get_value_as_format(provider.amount), main_target.get_text() ]

func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  for tile in _get_targets(effect_ctx):
    var target = GridManager.inst.get_tile_at(tile)
    if target:
      target.stat.add_provider(stat, provider)
