extends TileEffect
class_name TileEffectNoNeighbors

const DIRECTIONS = [
  Vector3i.LEFT,
  Vector3i.RIGHT,
  Vector3i.BACK,
  Vector3i.FORWARD,
  Vector3i(1, 0, 1),
  Vector3i(-1, 0, 1),
  Vector3i(1, 0, -1),
  Vector3i(-1, 0, -1)
]

@export var points_per_empty := 2

func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  _reward_points(effect_ctx, _get_points(effect_ctx))
  
func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "For each empty tile around this one, gain %d points ([color=#c69fa5]%s[/color])" % [ points_per_empty, _get_points(effect_ctx) ]

func _get_points(effect_ctx: EffectContext) -> int:
  var my_loc = GridManager.inst.get_tile_loc(effect_ctx.tile)
  var count = DIRECTIONS.reduce(func(accum, next): return accum if GridManager.inst.has_tile(next+my_loc) else accum+1, 0)
  return _get_total_points(effect_ctx, count*points_per_empty)
