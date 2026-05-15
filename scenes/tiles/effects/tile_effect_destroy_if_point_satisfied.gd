extends TileEffect
class_name TileEffectDestroyIfPointSatisfied

"""
This is not intended to be used through the normal def system,
but rather exists for Tile Caches
"""

var pt_source: PointSource

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "Dawn produced from marked tiles instead goes here. When amount is fulfilled, destroy this tile. Requires [color=#c69fa5]%d[/color] more." % [ pt_source.target-pt_source.current ]

func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  if pt_source.target <= pt_source.current:
    effect_ctx.tile.destroy()
