extends TileEffect
class_name TileEffectStatChance

@export var chance := 0.5 
@export var stat: StatDef
@export var provider: StatProviderDef
@export var target: TileTargetDef

func get_description(effect_ctx: EffectContext, _exec_ctx: ExecutionContext) -> String:
  return "Has a %.0f%% chance to apply %s %s to %s" % [
    chance*100.0,
    StatProviderDef.get_value_as_format(provider.amount),
    stat.name,
    target.get_text()
  ]
  
func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  if randf() > chance:
    await effect_ctx.tile.get_tree().create_timer(0.5).timeout
    return
  
  var targets = target.get_target(effect_ctx)

  for t: Vector3i in targets:
    var tile = GridManager.inst.get_tile_at(t)
    if tile:
      tile.stat.add_provider(stat, provider)
      effect_ctx.tile.stretcher.punch(3.0, 6.0)
      tile.stretcher.punch(3.0, 6.0)
      print("applied %s" % str(t))
