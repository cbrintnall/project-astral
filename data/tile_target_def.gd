extends Resource
class_name TileTargetDef

@export var tiles: Array[Vector3i] = []
@export var include_self := true
@export var random_amount_from_tiles := 0
@export var size := Vector2i.ZERO
@export var row := false
@export var column := false
@export var random_cardinal_direction := false
@export var random_neighbors := 0

func get_text():
  var text := []
  var amount := mini(len(tiles), random_amount_from_tiles)
  
  if random_cardinal_direction:
    text.push_back("in a random cardinal direction")
    
  if random_neighbors:
    text.push_back("for up to [color=#c69fa5]%d[/color] random neighbor(s)"% random_neighbors)
  
  if amount:
    text.push_back("for [color=#c69fa5]%d[/color] %s neighbor%s" % [
      amount, 
      "random" if random_amount_from_tiles > 0 else "", 
      "s" if amount > 1 else ""
    ])
    
  if size:
    text.push_back("in an [color=#c69fa5]%dx%d[/color] area" % [size.x,size.y])
  
  if include_self:
    text.push_back("for [color=#c69fa5]itself[/color]")
    
  if len(text) > 1:
    text[-1] = "and %s" % text[-1]
    
  if row:
    text.push_back("in the same row")
    
  if column:
    text.push_back("in the same column")
  
  var base_text = ", ".join(text)
  
  return base_text

func get_target(ctx: EffectContext) -> Array:
  var targets := []
  var viable_options := tiles.duplicate()
  var src = GridManager.inst.get_tile_loc(ctx.tile)

  if not ctx.tile.placed and ctx.override_location:
    src = ctx.override_location
  
  if random_cardinal_direction:
    targets.push_back(Constants.CARDINAL_DIRECTIONS.pick_random())
  
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
      
  if random_neighbors:
    var viable = ctx.tile.get_neighbors()
    if viable:
      viable.shuffle()
    for i in mini(len(viable), random_neighbors):
      targets.push_back(GridManager.inst.get_tile_loc(viable.pop_front()))
      
  if row:
    var loc = GridManager.inst.get_tile_loc(ctx.tile)
    var next = Vector3i.LEFT
    while GridManager.inst.is_in_bounds(loc+next):
      targets.push_back(loc+next)
      next += Vector3i.LEFT
    next = Vector3i.RIGHT
    while GridManager.inst.is_in_bounds(loc+next):
      targets.push_back(loc+next)
      next += Vector3i.RIGHT
      
  if column:
    var loc = GridManager.inst.get_tile_loc(ctx.tile)
    var next = Vector3i.FORWARD
    while GridManager.inst.is_in_bounds(loc+next):
      targets.push_back(loc+next)
      next += Vector3i.FORWARD
    next = Vector3i.BACK
    while GridManager.inst.is_in_bounds(loc+next):
      targets.push_back(loc+next)
      next += Vector3i.BACK
      
  targets = targets.filter(func(tile: Vector3i): return GridManager.inst.is_in_bounds(tile))
      
  return targets
