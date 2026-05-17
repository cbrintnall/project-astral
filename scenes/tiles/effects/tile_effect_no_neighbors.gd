extends TileEffect
class_name TileEffectNoNeighbors

@export var points_per_empty: float = 2

func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  _reward_points(effect_ctx, get_tile_baseline_points(effect_ctx))
  
func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "For each empty tile, gain %+.2f points ([color=#c69fa5]%s[/color])" % [ points_per_empty, _get_total_points(effect_ctx, get_tile_baseline_points(effect_ctx)) ]

func get_tile_baseline_points(effect_ctx: EffectContext) -> int:
  var targets = main_target.get_target(effect_ctx)
  var count = targets.reduce(func(accum, next): return accum if GridManager.inst.has_tile(next) else accum+1, 0)
  return count*points_per_empty
