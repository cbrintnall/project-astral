extends TileEffect
class_name TileEffectPointPerHealth

@export var amount_per := 5

func _get_total_health(ctx: EffectContext) -> int:
  var tiles = main_target.get_target(ctx, true)
  var total_health := 0
  for pos: Vector3i in tiles:
    var tile: Tile = GridManager.inst.get_tile_at(pos)
    total_health+=tile.health
  return total_health

func get_tile_baseline_points(effect_ctx: EffectContext) -> int:
  var health = _get_total_health(effect_ctx)
  if effect_ctx.tile:
    return _get_total_points(effect_ctx, effect_ctx.tile.health * amount_per)
  return 0
  
func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  var health = _get_total_health(effect_ctx)
  var txt = "Gives [color=#c69fa5]%d[/color] dawn per health" % amount_per
  if health:
    txt += " (%d)" % health
  return txt
  
func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  _reward_points(effect_ctx, get_tile_baseline_points(effect_ctx))
