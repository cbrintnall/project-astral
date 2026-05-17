@abstract
extends TileEffect
class_name TileEffectMatchingTiles

func _get_count(ctx: EffectContext):
  var tiles = main_target.get_target(ctx)
  var total_health := 0
  for pos: Vector3i in tiles:
    var tile: Tile = GridManager.inst.get_tile(pos)
    total_health+=tile.health
  return total_health
