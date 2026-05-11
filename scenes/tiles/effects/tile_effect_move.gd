extends TileEffect
class_name TileEffectMove

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "Moves %s" % [ main_target.get_text() ]

func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  var t: Tween = effect_ctx.tile.try_move(main_target.get_target(effect_ctx).front())
  await t.finished
