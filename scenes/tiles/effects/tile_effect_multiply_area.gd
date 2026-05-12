extends TileEffect
class_name TileEffectMultiplyArea

@export var size := Vector2i.ONE
@export var multiplier := 2.0

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "All tiles %s give an additional %.0f%% dawn." % [main_target.get_text(), multiplier*100.0]
  
func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  var points = main_target.get_target(effect_ctx)
  
  for pt in points:
    var ctx := GridManager.inst.get_mods_at_point(pt)
    ctx.points_multipliers += multiplier
    GridManager.inst.upgrade_grid_context(pt, ctx)
    
  effect_ctx.tile.tree_exiting.connect(
    func():
      for pt in points:
        var ctx := GridManager.inst.get_mods_at_point(pt)
        ctx.points_multipliers -= multiplier
        GridManager.inst.upgrade_grid_context(pt, ctx),
    CONNECT_ONE_SHOT
  )
