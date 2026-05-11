extends TileEffect
class_name TileEffectSpawnNoNeighbor

@export var spawn: TileDef
## 8 would be all sides
@export var amount := 8

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "If any tile has no neighbor, spawn %d [color=#c69fa5]%s[/color] around it." % [amount, spawn.name]
  
func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  var tiles := GridManager.inst.get_played_tiles()
  for tile: Tile in tiles:
    if tile == effect_ctx.tile or tile.def.initiates: continue

    if tile.no_neighbors():
      var open = tile.get_open_neighbors()
      open.shuffle()
      for i in amount:
        var next = load("res://scenes/board/tile.tscn").instantiate()
        next.def = spawn
        GridManager.inst.try_place_tile(next, open.pop_front())
