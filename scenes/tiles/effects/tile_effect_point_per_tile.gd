extends TileEffect
class_name TileEffectPointPerTarget

@export var per_tile := 2

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "Gives %d dawn per tile (%d) %s" % [per_tile, len(main_target.get_target(effect_ctx)), main_target.get_text()]
  
func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  _reward_points(effect_ctx,  len(main_target.get_target(effect_ctx))*per_tile) 
