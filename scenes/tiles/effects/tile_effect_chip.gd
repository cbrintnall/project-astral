@tool
extends TileEffect
class_name TileEffectChip

@export var amount := 1
  
func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "Chip the marked tiles by %d. Chip damages tiles if their chip is higher than defense." % [ amount ]
  
func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  var targets = main_target.get_target(effect_ctx)
  var ctx := VfxContext.new()
  
  ctx.delay_range = Vector2(0.1,0.3)
  ctx.duration_range = Vector2(0.3,0.8)
  ctx.on_step.connect(func(idx: int): GridManager.inst.get_tile_at(targets[idx]).do_chip_damage(amount))
  
  VfxManager.inst.do_ranged_effect(
    effect_ctx.tile.global_position,
    targets,
    3.0,
    ctx
  )
  
  await ctx.on_finish
