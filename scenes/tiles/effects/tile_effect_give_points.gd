extends TileEffect
class_name TileEffectGivePoints

@export var points_given := 1

func get_tile_baseline_points(effect_ctx: EffectContext) -> int:
  return points_given

func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  _reward_points(effect_ctx, get_tile_baseline_points(effect_ctx))
  await effect_ctx.tile.get_tree().create_timer(0.2).timeout
  
func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  var total = _get_total_points(effect_ctx, points_given)
  return "%s [color=#c69fa5]%d[/color] dawn." % [ "Creates" if points_given >= 0 else "Removes", abs(total) ]
