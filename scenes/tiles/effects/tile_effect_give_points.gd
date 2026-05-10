extends TileEffect
class_name TileEffectGivePoints

@export var points_given := 1

func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  AudioManager3d.play({
    "stream": preload("res://audio/Light Drone Sound (button hover) 34.wav"),
    "parent": self
  })
  _reward_points(effect_ctx, points_given)
  await effect_ctx.tile.get_tree().create_timer(0.2).timeout
  
func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  var total = _get_total_points(effect_ctx, points_given)
  return "%s %d dawn." % [ "Creates" if points_given >= 0 else "Removes", abs(total) ]
