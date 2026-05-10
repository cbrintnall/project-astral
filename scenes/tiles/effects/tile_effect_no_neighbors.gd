extends TileEffect
class_name TileEffectNoNeighbors

@export var points_per_empty := 2

func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  _reward_points(effect_ctx, _get_points(effect_ctx))
  
func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "For each empty tile %s, gain %d points ([color=#c69fa5]%s[/color])" % [ main_target.get_text(), points_per_empty, _get_points(effect_ctx) ]

func _get_points(effect_ctx: EffectContext) -> int:
  var targets = main_target.get_target(effect_ctx)
  var count = targets.reduce(func(accum, next): return accum if GridManager.inst.has_tile(next) else accum+1, 0)
  return _get_total_points(effect_ctx, count*points_per_empty)
