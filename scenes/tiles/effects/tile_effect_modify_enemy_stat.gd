extends TileEffectModifyStat
class_name TileEffectModifyEnemyStat

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "%s %s by %s for enemies %s." % [ description_verbiage, stat.name, StatProviderDef.get_value_as_format(provider.amount), main_target.get_text() ]

func _get_targets(ctx: EffectContext):
  return super._get_targets(ctx).filter(
    func(tile: Vector3i): return GridManager.inst.has_tile(tile) and GridManager.inst.get_tile_at(tile).def.is_enemy
  )
