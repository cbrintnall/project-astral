extends CycleEffect
class_name CycleEffectSpawnUnknownTiles

@export var range_given := Vector2i(1, 2)

func get_description() -> String:
  return "%d to %d unstable rifts will spawn." % [range_given.x,range_given.y]
  
func on_cycle_start():
  var claimed := []
  var amount := randi_range(range_given.x, range_given.y)
  
  for i in amount:
    var spot = GridManager.inst.try_claim_random_open_tile()
    if spot != Vector3i.MIN:
      claimed.push_back(spot)
    
  print("spawning %d / %d caches" % [len(claimed), amount])
    
  for spot: Vector3i in claimed:
    var ctx := VfxContext.new()
    ctx.duration_range = Vector2(0.5, 1.0)
    ctx.on_finish.connect(
      func():
        BoardCamera.inst.shake(0.2, 0.5)
        var cache = load("res://scenes/tiles/tile_cache.tscn").instantiate()
        cache.default_state = "display"
        if GridManager.inst.try_place_tile(cache, spot):
          cache.global_position = Vector3(spot)
        else:
          push_error("Cache failed to place, there is likely an issue in the grid tile claim")
    )
    VfxManager.inst.do_light_beam(Vector3(spot), ctx)
