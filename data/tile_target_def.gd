extends Resource
class_name TileTargetDef

@export var tiles: Array[Vector3i] = []
@export var include_self := true
@export var random_amount_from_tiles := 0
@export var row := false
@export var column := false

func get_text():
  var amount := mini(len(tiles), random_amount_from_tiles)
  var base_text := "[color=#c69fa5]%d[/color] %s neighbor%s" % [
    amount, 
    "random" if random_amount_from_tiles > 0 else "", 
    "s" if amount > 1 else ""
  ]
  
  if include_self:
    base_text += ", and [color=#c69fa5]itself[/color]"
  
  base_text += "."
  
  return base_text

func get_target(ctx: EffectContext) -> Array:
  var targets := []
  var viable_options := tiles.duplicate()
  
  if include_self:
    viable_options.push_back(Vector3i.ZERO)
    
  var src = GridManager.inst.get_tile_loc(ctx.tile)
  
  if random_amount_from_tiles > 0:
    viable_options.shuffle()
    for i in mini(len(tiles), random_amount_from_tiles):
      targets.push_back(src+viable_options.pop_back())
  else:
    for dir in tiles:
      targets.push_back(src+dir)
      
  return targets
