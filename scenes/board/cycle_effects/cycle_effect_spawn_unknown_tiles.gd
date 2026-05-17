extends TileEffect
class_name CycleEffectSpawnUnknownTiles

const SLOW_TIME = 2.0

@export var range_given := Vector2i(1, 2)

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "%d to %d unstable rifts will spawn." % [range_given.x,range_given.y]
  
func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  var claimed := []
  var amount := randi_range(range_given.x, range_given.y)
  var targets = main_target.get_target(effect_ctx)
  targets.shuffle()
  
  for i in mini(amount, len(targets)):
    var spot = targets.pop_front()
    if spot != Vector3i.MIN:
      claimed.push_back(spot)
    
  print("spawning %d / %d caches" % [len(claimed), amount])
    
  for spot: Vector3i in claimed:
    var ctx := VfxContext.new()
    ctx.duration_range = Vector2(0.5, 1.0)
    ctx.on_finish.connect(
      func():
        BoardCamera.inst.shake(0.2, 0.5)
        var cache: Tile = load("res://scenes/tiles/tile_cache.tscn").instantiate()
        cache.faction = Tile.Faction.NEUTRAL
        Engine.time_scale = 0.05
        var t = GameManager.inst.create_tween()
        t.set_ignore_time_scale(true)
        t.parallel().tween_method(func(energy: float): GameManager.inst.light.light_energy = energy, 3.0, 1.0, SLOW_TIME).set_trans(Tween.TRANS_QUAD)
        t.parallel().tween_property(Engine, "time_scale", 1.0, SLOW_TIME).set_trans(Tween.TRANS_CUBIC)
        
        cache.default_state = "display"
        if GridManager.inst.try_place_tile(cache, spot):
          cache.global_position = Vector3(spot)
        else:
          push_error("Cache failed to place, there is likely an issue in the grid tile claim")
    )
    VfxManager.inst.do_light_beam(Vector3(spot), ctx)
    await ctx.on_finish
    await GameManager.inst.get_tree().create_timer(SLOW_TIME, true, false, true).timeout
