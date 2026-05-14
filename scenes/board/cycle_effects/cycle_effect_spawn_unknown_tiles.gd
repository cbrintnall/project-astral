extends CycleEffect
class_name CycleEffectSpawnUnknownTiles

@export var amount := 4

func on_cycle_end():
  pass
  
func on_cycle_start():
  var claimed := []
  
  for i in amount:
    var spot = GridManager.inst.try_claim_random_open_tile()
    if spot != Vector3i.MIN:
      claimed.push_back(spot)
    
  print("spawning %d / %d caches" % [len(claimed), amount])
    
  for spot: Vector3i in claimed:
    var cache = load("res://scenes/tiles/tile_cache.tscn").instantiate()
    cache.default_state = "display"
    if GridManager.inst.try_place_tile(cache, spot):
      cache.global_position = Vector3(spot)
    else:
      push_error("Cache failed to place, there is likely an issue in the grid tile claim")
