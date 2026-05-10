extends Resource
class_name TileTargetDef

@export var tiles: Array[Vector3i] = []
@export var include_self := true
@export var random_amount_from_tiles := 0
@export var size := Vector2i.ZERO
@export var row := false
@export var column := false

func get_text():
  var text := []
  var amount := mini(len(tiles), random_amount_from_tiles)
  
  if amount:
    text.push_back("[color=#c69fa5]%d[/color] %s neighbor%s" % [
      amount, 
      "random" if random_amount_from_tiles > 0 else "", 
      "s" if amount > 1 else ""
    ])
    
  if size:
    text.push_back("in a [color=#c69fa5]%dx%d[/color] area" % [size.x,size.y])
  
  if include_self:
    text.push_back("[color=#c69fa5]itself[/color]")
    
  if len(text) > 1:
    text[-1] = "and %s" % text[-1]
  
  var base_text = ", ".join(text)
  
  return base_text

func get_target(ctx: EffectContext) -> Array:
  var targets := []
  var viable_options := tiles.duplicate()
  var src = GridManager.inst.get_tile_loc(ctx.tile)

  if not ctx.tile.placed and ctx.override_location:
    src = ctx.override_location
  
  if size:
    var rect = Rect2i(Vector2i(src.x, src.z)-Vector2i((size*0.5).floor()), size)
    var area_tiles = Utils.get_points(rect).map(func(pt): return Vector3i(pt.x, 0, pt.y))
    area_tiles.erase(src)
    targets.append_array(area_tiles)
  
  if include_self:
    viable_options.push_back(Vector3i.ZERO)
  
  if random_amount_from_tiles > 0:
    viable_options.shuffle()
    for i in mini(len(tiles), random_amount_from_tiles):
      targets.push_back(src+viable_options.pop_back())
  else:
    for dir in tiles:
      targets.push_back(src+dir)
      
  return targets
