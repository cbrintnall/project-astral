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
@export var every_tile := false
@export var empty_space := false
@export var pull_random_amount := Vector2i.ZERO
@export var only_empty := false
@export var only_taken := false
@export var faction := Tile.Faction.ALL

func should_preview_spots() -> bool:
  if random_cardinal_direction:
    return false
  
  if random_neighbors:
    return false
    
  return true

func get_text_tags() -> PackedStringArray:
  var text := PackedStringArray()
  
  if only_taken:
    text.push_back("non-empty")
  
  if only_empty:
    text.push_back("empty")

  if random_cardinal_direction:
    text.push_back("random direction")
    
  if size:
    text.push_back("[color=#c69fa5]%d[/color]x[color=#c69fa5]%d[/color]" % [size.x,size.y])
  
  if include_self:
    text.push_back("self")
    
  if row:
    text.push_back("row")
    
  if column:
    text.push_back("column")
    
  if random_neighbors:
    text.push_back("[color=#c69fa5]%d[/color] neighbors" % random_neighbors)
    
  match faction:
    Tile.Faction.ENEMY:
      text.push_back("targets \"enemies\"")
    Tile.Faction.PLAYER:
      text.push_back("targets \"player\"")
      
  if every_tile and not only_taken:
    text.push_back("placed tiles")
    
  if empty_space and not only_empty:
    text.push_back("empty spaces")
    
  if pull_random_amount:
    if pull_random_amount.x == pull_random_amount.y:
      var txt = "[color=#c69fa5]%d[/color] random tile" % [pull_random_amount.x]
      if pull_random_amount.x > 1:
        txt += "s"
      text.push_back(txt)
    else:
      text.push_back("between [color=#c69fa5]%d[/color]-[color=#c69fa5]%d[/color] random tiles" % [pull_random_amount.x,pull_random_amount.y])
  
  return text

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
  
  if every_tile:
    var txt = "for all tiles on the board"
    if include_self:
      txt += ", including itself"
    text.push_back(txt)
  elif include_self:
    text.push_back("on [color=#c69fa5]itself[/color]")
    
  if len(text) > 1:
    text[-1] = "and %s" % text[-1]
    
  if row:
    text.push_back("in the same row")
    
  if column:
    text.push_back("in the same column")
  
  var base_text = ", ".join(text)
  
  return base_text

func get_target(ctx: EffectContext, with_tiles := false, ignore_filters := false) -> Array:
  var targets := []
  var viable_options := tiles.duplicate()
  var src = ctx.override_location

  if not src and ctx.tile:
    src = GridManager.inst.get_tile_loc(ctx.tile)

  if empty_space:
    targets.append_array(GridManager.inst.get_all_open_spaces())

  if random_cardinal_direction:
    targets.push_back(src+Constants.CARDINAL_DIRECTIONS.pick_random())
  
  if size:
    var rect = Rect2i(Vector2i(src.x, src.z)-Vector2i((size*0.5).floor()), size)
    var area_tiles = Utils.get_points(rect).map(func(pt): return Vector3i(pt.x, 0, pt.y))
    area_tiles.erase(src)
    targets.append_array(area_tiles)
  
  # before include self to decide if we want to include it
  if every_tile:
    targets.append_array(GridManager.inst.get_played_tiles().map(GridManager.inst.get_tile_loc))
    targets.erase(src)
    
  if include_self:
    targets.push_back(src)
  
  if random_amount_from_tiles > 0:
    viable_options.shuffle()
    for i in mini(len(tiles), random_amount_from_tiles):
      targets.push_back(src+viable_options.pop_back())
  else:
    for dir in tiles:
      targets.push_back(src+dir)
      
  if random_neighbors:
    var viable = GridManager.inst.get_neighbors_for(src)
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
  
  if not ignore_filters:
    if faction != Tile.Faction.ALL:
      with_tiles = true
      
    if with_tiles:
      targets = targets.filter(GridManager.inst.has_tile)
    
    if faction != Tile.Faction.ALL:
      targets = targets.filter(func(pos: Vector3i): return GridManager.inst.get_tile_at(pos).faction == faction)
      
    if only_empty:
      targets = targets.filter(func(pos: Vector3i): return not GridManager.inst.has_tile(pos))
      
    if only_taken:
      targets = targets.filter(GridManager.inst.has_tile)
      
    if pull_random_amount:
      var amount = mini(randi_range(pull_random_amount.x, pull_random_amount.y), len(targets))
      var culled = []
      targets.shuffle()
      for i in amount:
        culled.push_back(targets.pop_front())
      targets = culled
    
  # ZERO is the center tile, erase it cause we never need to target it
  targets.erase(Vector3i.ZERO)
      
  return targets
