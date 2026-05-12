extends RefCounted
class_name EffectContext

var tile: Tile
var override_location: Vector3i

func get_location() -> Vector3i:
  if override_location:
    return override_location
    
  return GridManager.inst.get_tile_loc(tile)
