extends Node
class_name GridManager

static var inst: GridManager

static var DEFAULT_COLOR := Color.from_string("#fbf5ef", Color.WHITE)
static var WARNING_COLOR := Color.from_string("#f2d3ab", Color.WHITE)
static var ERROR_COLOR := Color.from_string("#c69fa5", Color.WHITE)

signal board_changed
signal mods_changed

@export var size := Vector2i.ONE

@onready var grid_map: GridMap = $GridMap
@onready var grid_cast: Gridcast = $Gridcast
@onready var selection: Node3D = $SelectionBox

var grid_position_3d: Vector3i
var center_tile: Tile

var grid_hovered_tile: Tile
var hand_hovered_tile: Tile
var hand_selected_tile: Tile

var _choose_cd := BetterTimer.new(0.1)
var _current_selection: Selection
var _placements := {}
var _tiles := {}
var _pos_modifications := {}

var _tiles_dirty := false

var _indicator_color := DEFAULT_COLOR
var _grid_material: ShaderMaterial = preload("res://materials/material_grid_selection_box.tres")

var _execution_paths := []
var _followers := []

func get_mods_at_point(loc: Vector3i) -> GridContext:
  return _pos_modifications.get(loc, GridContext.new())
  
func get_mods() -> Dictionary:
  return _pos_modifications
  
func upgrade_grid_context(loc: Vector3i, ctx: GridContext):
  _pos_modifications[loc] = ctx
  mods_changed.emit()

func tiles_dirty() -> bool:
  return _tiles_dirty

func collect_tiles_in_execution_order() -> Array:
  var tiles := []
  
  var initiators = get_played_tiles().filter(func(tile: Tile): return tile.def.initiates)

  for initiator in initiators:
    _collect_tile(initiator, _tiles[initiator], tiles)
  
  return tiles

func get_tile_at(pos: Vector3i) -> Tile:
  return _placements.get(pos)

func get_played_tiles() -> Array:
  return _tiles.keys()

func get_tile_loc(tile: Tile) -> Vector3i:
  return _tiles.get(tile, Vector3i.MIN)

func map_to_global(tile: Vector3i) -> Vector3:
  return grid_map.to_global(grid_map.map_to_local(tile))

func has_tile(loc: Vector3i) -> bool:
  return get_tile_at(loc) != null

func try_place_tile(tile: Tile, pos: Vector3i) -> bool:
  if _placements.has(pos): return false

  var has_neighbor = Tile.DIRECTION_EXECUTION_ORDER.any(
    func(dir: Vector2i): return has_tile(pos+Vector3i(dir.x, 0, dir.y))
  )
  
  if not has_neighbor and not tile.def.initiates:
    return false
  
  _placements[pos] = tile
  _tiles[tile] = pos

  NodeUtils.force_child(grid_map, tile)
  tile.global_position = pos
  tile.set_placed_at(pos)
  _tiles_dirty = true
  tile.tree_exiting.connect(
    func():
      _tiles.erase(tile)
      _placements.erase(pos)
      _tiles_dirty = true,
    CONNECT_ONE_SHOT
  )
  
  return true

func try_start_selection(data: Selection) -> bool:
  if _current_selection:
    if _current_selection.can_cancel:
      _current_selection.cancel()
    else:
      return false
      
  _current_selection = data
  _current_selection.canceled.connect(func(): _current_selection = null)
  _current_selection.started.emit()
  _choose_cd.reset()

  return true
  
func _input(event: InputEvent) -> void:
  if event.is_action_pressed("ui_cancel"):
    _cancel_current_selection()
    
  # timer cooldown so we don't immediately do something after creating selection
  # everything below this if statement should be selection related
  if _choose_cd.progress < 1.0: return
    
  if event is InputEventMouseButton:
    if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
      if _current_selection and _current_selection.on_choose.is_valid():
        _current_selection.on_choose.call()
        get_viewport().set_input_as_handled()
  
func _collect_tile(current: Tile, current_pos: Vector3i, collection: Array):
  if collection.has(current):
    return

  collection.push_back(current)

  for dir: Vector2i in current.get_directions():
    var world_tile = current_pos+Vector3i(dir.x, 0, dir.y)
    var next = get_tile_at(world_tile)
    if next:
      _collect_tile(next, world_tile, collection)

func _update_dirty_grid():
  for node in get_tree().get_nodes_in_group("debug_path_text"):
    node.queue_free()
  
  var execution_order = collect_tiles_in_execution_order()
  for i in len(execution_order):
    var text := Label3D.new()
    var tile = execution_order[i]
    
    tile.add_child(text)
    text.text = str(i+1)
    text.position = Vector3.UP*1.5
    text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    text.add_to_group("debug_path_text")
    #
  #for path in _execution_paths:
    #path.queue_free()
    #
  #_execution_paths = []
  #_followers = []
  #
  #var path := Path3D.new()
  #path.curve = Curve3D.new()
  #var follower := PathFollow3D.new()
  #for tile in execution_order:
    #path.curve.add_point(path.to_local(tile.global_position))
  #add_child(path)
  #path.add_child(follower)
  #var mesh := MeshInstance3D.new()
  #mesh.mesh = SphereMesh.new()
  #follower.add_child(mesh)
  #
  #_execution_paths.push_back(path)
  #_followers.push_back(follower)
    
  board_changed.emit()

func _cancel_current_selection():
  if _current_selection:
    if _current_selection.can_cancel:
      _current_selection.cancel()
      _current_selection = null

func _ready() -> void:
  inst = self
  
func _process(delta: float) -> void:
  _choose_cd.check(delta, false)
  
  if _tiles_dirty:
    _update_dirty_grid()
    _tiles_dirty = false
    
  for follower: PathFollow3D in _followers:
    follower.progress += delta
  
  if not grid_cast.ray_data: return

  var grid_pos: Vector3 = grid_cast.ray_data["position"]
  RenderingServer.global_shader_parameter_set("global_mouse_position", grid_pos)
  var raw_pos = grid_pos+grid_pos.sign()*0.5
  var raw_tile = Vector3i(raw_pos)
  grid_position_3d = map_to_global(raw_tile)
  selection.global_position = grid_position_3d
  selection.visible = _current_selection != null
  
  grid_hovered_tile = get_tile_at(grid_position_3d)
  
  if _current_selection:
    var target = DEFAULT_COLOR
    match _current_selection.state:
      Selection.State.WARNING:
        target = WARNING_COLOR
      Selection.State.ERROR:
        target = ERROR_COLOR
        
    _indicator_color = _indicator_color.lerp(target, 0.1)
  
  if selection.visible:
    _grid_material.set_shader_parameter("clr", _indicator_color)

  DebugDraw2D.set_text("hovered path", grid_hovered_tile.get_path() if grid_hovered_tile else "n/a")
  DebugDraw2D.set_text("hovered tile position", grid_position_3d)
  DebugDraw2D.set_text("hovered position", raw_pos)
