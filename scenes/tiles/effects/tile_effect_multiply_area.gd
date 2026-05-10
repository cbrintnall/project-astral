extends TileEffect
class_name TileEffectMultiplyArea

@export var size := Vector2i.ONE
@export var multiplier := 2.0

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "All tiles with an %dx%d area give an addition %.0f%% dawn." % [size.x,size.y, multiplier*100.0]
  
func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  var tile = GridManager.inst.get_tile_loc(effect_ctx.tile)
  var rect = Rect2i(Vector2i(tile.x, tile.z)-Vector2i((size*0.5).floor()), size)
  var points = Utils.get_points(rect).map(func(pt): return Vector3i(pt.x, 0, pt.y))
  
  for pt in points:
    var ctx := GridManager.inst.get_mods_at_point(pt)
    ctx.points_multipliers += multiplier
    GridManager.inst.upgrade_grid_context(pt, ctx)
    
  effect_ctx.tile.tree_exiting.connect(
    func():
      for pt in points:
        var ctx := GridManager.inst.get_mods_at_point(pt)
        ctx.points_multipliers -= multiplier
        print(ctx.points_multipliers)
        GridManager.inst.upgrade_grid_context(pt, ctx),
    CONNECT_ONE_SHOT
  )
