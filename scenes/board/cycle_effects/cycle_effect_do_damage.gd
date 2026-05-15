extends TileEffect
class_name CycleEffectGiveChip

@export var amount := 1

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "Nyx will fire arrows at the marked tiles, dealing %d damage." % amount

func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  var targets = main_target.get_target(effect_ctx, true)
  var context := VfxContext.new()
  
  context.on_step.connect(func(idx: int): GridManager.inst.get_tile_at(targets[idx]).do_chip_damage(amount))
  context.delay_range = Vector2(0.1, 1.0)
  context.duration_range = Vector2(1.0, 2.0)
  context.transition = Tween.TransitionType.TRANS_QUAD
  
  VfxManager.inst.do_ranged_effect(
    Vector3.RIGHT*(GridManager.inst.size.x * 3.0),
    targets,
    30.0,
    context,
  )
  
  await context.on_finish
