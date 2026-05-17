extends TileEffect
class_name TileEffectGiveDefense

@export var amount := 1

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "Gives %d defense." % amount

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
      tile.defense += amount
  )
  
  VfxManager.inst.do_icons_at(
    load("res://assets/vfx/vfxShield_Cube.res"),
    pts,
    1.0,
    ctx
  )
  
  await ctx.on_finish
