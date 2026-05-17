extends TileEffect
class_name CycleEffectGiveChip

@export var amount := 1

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "Nyx will fire arrows at the marked tiles, dealing %d damage." % amount

func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  var targets = main_target.get_target(effect_ctx)
  var context := VfxContext.new()
  
  context.on_step.connect(func(idx: int): GridManager.inst.get_tile_at(targets[idx]).do_chip_damage(amount))
  context.delay_range = Vector2(0.1, 0.7)
  context.duration_range = Vector2(0.5, 1.0)
  context.transition = Tween.TransitionType.TRANS_QUAD
  context.on_step_started.connect(func(_idx: int): 
    AudioManager3d.play({
      "stream": preload("res://audio/Releasing Bow String 1.wav"),
      "pitch_variance": 0.15,
      "location": GridManager.inst.get_viewport().get_camera_3d().global_position + (Vector3.RIGHT*15.0)
    })
  )
  
  VfxManager.inst.do_ranged_effect(
    Vector3.RIGHT*(GridManager.inst.size.x * 3.0),
    targets,
    30.0,
    context,
  )
  
  await context.on_finish
