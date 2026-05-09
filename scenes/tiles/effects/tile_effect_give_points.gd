extends TileEffect
class_name TileEffectGivePoints

@export var points_given := 1

func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  GameManager.inst.current_score += points_given
  AudioManager3d.play({
    "stream": preload("res://audio/Light Drone Sound (button hover) 34.wav"),
    "parent": self
  })
  
func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "Creates %d dawn." % points_given
