extends TileEffect
class_name TileEffectMove

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "Moves %s" % [ main_target.get_text() ]

func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  var target_tile = main_target.get_target(effect_ctx).front()
  var res: ResolutionCommand = GridManager.inst.submit_move_attempt(effect_ctx.tile, target_tile, exec_ctx)
  exec_ctx.register_resolution(res)
