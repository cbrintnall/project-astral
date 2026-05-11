extends TileEffect
class_name TileEffectTransformLonely

@export var transform_to: TileDef

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "Transform any tile with no neighbor into [color=#c69fa5]%s[/color]" % transform_to.name

func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  var tiles := GridManager.inst.get_played_tiles()
  for tile: Tile in tiles:
    if tile == effect_ctx.tile or tile.def.initiates: continue

    if tile.no_neighbors():
      tile.transform_to(transform_to)
