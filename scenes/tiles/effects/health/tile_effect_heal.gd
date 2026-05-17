extends TileEffect
class_name TileEffectHeal

@export var amount := 1

func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  var pts := main_target.get_target(effect_ctx, true)
  
  if not pts:
    return
  
  var ctx := VfxContext.new()
  
  ctx.delay_range = Vector2(0.0, 0.2)
  ctx.duration_range = Vector2(1.0, 1.5)
  ctx.on_step_started.connect(
    func(idx: int): 
      var tile: Tile = GridManager.inst.get_tile_at(pts[idx])
      tile.health += amount
      AudioManager3d.play({
        "stream": preload("res://audio/healed.ogg"),
        "pitch_variance": 0.1,
        "parent": tile,
        "debounce": 0.1
      })
  )
  
  VfxManager.inst.do_icons_at(
    load("res://assets/vfx/vfxHeart_Heart_Full.res"),
    pts,
    1.0,
    ctx
  )
  
  await ctx.on_finish

  
func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "Heals for %d" % amount
