extends TileEffect
class_name TileEffectSpawnMatching

@export var tile: TileDef
## NOTE: use this to avoid circular references
@export var tile_path: StringName

func _init():
  if not tile:
    tile = load(tile_path)

func clone() -> TileEffect:
  var base = super()
  
  base.tile = tile
  if not tile and tile_path:
    base.tile = load(tile_path)
  return base

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "Spawn [color=#c69fa5]\"%s\"[/color] in marked spaces." % tile.name
  
func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  for pos: Vector3i in main_target.get_target(effect_ctx):
    if GridManager.inst.could_place_tile(pos):
      var board_tile = load("res://scenes/board/tile.tscn").instantiate()
      board_tile.def = tile
      GridManager.inst.try_place_tile(board_tile, pos)
      await GameManager.inst.get_tree().create_timer(0.2).timeout
