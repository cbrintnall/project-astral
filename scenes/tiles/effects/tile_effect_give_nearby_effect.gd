extends TileEffect
class_name TileEffectGiveNearbyEffect

@export var effect: TileEffect

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "Gives %s an %s that \"%s\"" % [ main_target.get_text(), effect.get_event_text(), effect.get_description(effect_ctx, exec_ctx) ]

func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  for pos: Vector3i in main_target.get_target(effect_ctx):
    var tile = GridManager.inst.get_tile_at(pos)

    if not tile: continue

    if not tile.has_effect(effect):
      tile.register_effect(effect)
