@tool
extends TileEffect
class_name TileEffectChip

@export var amount := 1
  
func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "Does %d damage." % [ amount ]
  
func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  var targets = main_target.get_target(effect_ctx, true)
  
  if not targets:
    return
  
  var ctx := VfxContext.new()
  
  ctx.delay_range = Vector2(0.1,0.3)
  ctx.duration_range = Vector2(0.3,0.8)
  ctx.on_step.connect(func(idx: int): GridManager.inst.get_tile_at(targets[idx]).do_chip_damage(amount))
  ctx.on_step_started.connect(func(_idx: int): 
    AudioManager3d.play({
      "stream": preload("res://audio/Releasing Bow String 1.wav"),
      "pitch_variance": 0.15,
      "location": effect_ctx.tile.global_position
    })
  )
  
  VfxManager.inst.do_ranged_effect(
    effect_ctx.tile.global_position,
    targets,
    3.0,
    ctx
  )
  
  await ctx.on_finish
