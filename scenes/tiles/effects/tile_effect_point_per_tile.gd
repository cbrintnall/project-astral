extends TileEffect
class_name TileEffectPointPerTarget

@export var per_tile := 2
  
func get_tile_baseline_points(effect_ctx: EffectContext) -> int:
  return len(main_target.get_target(effect_ctx, true))*per_tile

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "Gives %d dawn per tile (%d) marked." % [per_tile, len(main_target.get_target(effect_ctx, true))]
  
func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  _reward_points(effect_ctx,  get_tile_baseline_points(effect_ctx)) 
