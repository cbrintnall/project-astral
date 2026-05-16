extends TileEffect
class_name TileEffectDestroyIfMatching

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "If all marked tiles are filled, destroys this tile."
  
func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  if main_target.get_target(effect_ctx).all(GridManager.inst.has_tile):
    effect_ctx.tile.destroy()
    
