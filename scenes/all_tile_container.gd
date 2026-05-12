@tool
extends ResourceCache
class_name AllTileContainer

var _tiles_by_name := {}

func is_resource(resource: Resource) -> bool:
  return resource is TileDef

func _ready() -> void:
  for tile: TileDef in resources:
    _tiles_by_name[tile.name.to_lower().replace(" ", "_")] = tile
    
  Console.add_command(
    "tiles",
    func():
      Console.print_line("\n- ".join(_tiles_by_name.keys()))
  )
  
  Console.add_command(
    "give_path", 
    _give, 
    ["path"]
  )
  
  Console.add_command(
    "give",
    _give_name,
    ["path"]
  )

func _give_name(path: String):
  var fixed = path.to_lower().replace(" ", "_")
  var tile = _tiles_by_name.get(fixed)
  
  if tile:
    TileHand.inst.add_to_hand(tile)
    print(tile)
  else:
    Console.print_error("%s (%s) isn't a valid tile." % [path, fixed])
    Console.print_line(", ".join(_tiles_by_name.keys()))

func _give(path: String):
  var tile = load(path)
  if tile and tile is TileDef:
    TileHand.inst.add_to_hand(tile)
