extends RefCounted
class_name EffectContext

static func from_tile(t: Tile) -> EffectContext:
  var ctx := EffectContext.new()
  ctx.tile = t
  return ctx

static func from_override(override: Vector3i) -> EffectContext:
  var ctx := EffectContext.new()
  ctx.override_location = override
  return ctx

var tile: Tile
var override_location: Vector3i

func get_location() -> Vector3i:
  if override_location:
    return override_location
    
  return GridManager.inst.get_tile_loc(tile)
