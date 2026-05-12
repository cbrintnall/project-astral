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
@onready var map_bounds: Node3D = $MapBounds
@onready var selection_boxes: MultiMeshInstance3D = %SelectionBoxes

var grid_position_3d: Vector3i
var center_tile: Tile

var grid_hovered_tile: Tile:
  set(val):
    if val != grid_hovered_tile:
      if _grid_tile_command:
        _grid_tile_command.undo()
        
      grid_hovered_tile = val
      
      if grid_hovered_tile:
        var data := TileDataPreviewer.TilePreviewData.new()
        data.priority = 0
        data.def = grid_hovered_tile.def
        data.effects = grid_hovered_tile.get_effects()
        data.context = EffectContext.new()
        data.context.tile = grid_hovered_tile
        _grid_tile_command = UI.inst.tile_previewer.push_preview(data)
  get:
    return grid_hovered_tile

var hand_hovered_tile: Tile:
  set(val):
    if val != hand_hovered_tile:
      if _hovered_tile_command:
        _hovered_tile_command.undo()
        
      hand_hovered_tile = val
      
      if hand_hovered_tile:
        var data := TileDataPreviewer.TilePreviewData.new()
        data.priority = 1
        data.def = hand_hovered_tile.def
        data.effects = hand_hovered_tile.get_effects()
        data.context = EffectContext.new()
        data.context.tile = hand_hovered_tile
        _hovered_tile_command = UI.inst.tile_previewer.push_preview(data)
  get:
    return hand_hovered_tile

var hand_selected_tile: Tile

var _choose_cd := BetterTimer.new(0.1)
var _current_selection: Selection
var _placements := {}
var _tiles := {}
var _pos_modifications := {}

var _tiles_dirty := false

var _indicator_color := DEFAULT_COLOR
var _grid_material: ShaderMaterial = preload("res://materials/material_grid_selection_box.tres")
var _bounds := Rect2i()

var _hovered_tile_command: Command
var _grid_tile_command: Command

var _hovered_tile_area_highlighter := GridHighlights.new()

var _move_attempts := {}

func is_in_bounds(pos: Vector3i) -> bool:
  return _bounds.has_point(Vector2i(pos.x, pos.z))

func try_move(tile: Tile, target: Vector3i) -> bool:
  if has_tile(target):
    return false
    
  assert(_tiles.has(tile))
    
  var original = get_tile_loc(tile)
  _tiles.erase(tile)
  _placements.erase(original)

  _tiles[tile] = target
  _placements[target] = tile
  
  tile.set_move(original, target)
  
  return true
  
func could_place_tile(loc: Vector3i) -> bool:
  return not get_tile_at(loc) and is_in_bounds(loc)

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
  return get_played_tiles()

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
  if not is_in_bounds(pos): return false
  
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
  
func submit_move_attempt(tile: Tile, target: Vector3i, ctx: ExecutionContext) -> MoveResolutionCommand:
  var attempting_tiles = _move_attempts.get_or_add(target, [])
  attempting_tiles.push_back(tile)
  
  print("trying to move from %s to %s" % [get_tile_loc(tile), str(target)])
  
  var resolution := MoveResolutionCommand.new(ctx)
  
  resolution.attempts = _move_attempts
  resolution.tile = tile
  resolution.target = target
  
  return resolution
  
func _unhandled_input(event: InputEvent) -> void:
  if event.is_action_pressed("ui_cancel"):
    _cancel_current_selection()
    
  match Utils.get_key_pressed(event):
    KEY_Z:
      if get_tile_at(grid_position_3d):
        get_tile_at(grid_position_3d).destroy()
    
  # timer cooldown so we don't immediately do something after creating selection
  # everything below this if statement should be selection related
  if _choose_cd.progress < 1.0: return
    
  if event is InputEventMouseButton:
    if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
      if _current_selection and _current_selection.on_choose.is_valid():
        _current_selection.on_choose.call()
  
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
    
  board_changed.emit()

func _cancel_current_selection():
  if _current_selection:
    if _current_selection.can_cancel:
      _current_selection.cancel()
      _current_selection = null

func _ready() -> void:
  inst = self
  _hovered_tile_area_highlighter.mesh = load("res://assets/extracted_mesh/area_indicator_mesh.tres")
  add_child(_hovered_tile_area_highlighter)
  map_bounds.scale = Vector3(size.x+2, size.x*0.25, size.y+2)
  _bounds = Rect2i(Vector2i((Vector2(-size)*Vector2(0.5, 0.5)).ceil()), size+Vector2i.ONE)
  
  print("rendering server grid size %s" % str(Vector2(size)))
  
  var t = create_tween()

  t.tween_method(
    func(time: float):
      var current = Vector2.ZERO.lerp(Vector2(size), time)
      RenderingServer.global_shader_parameter_set("grid_size", current),
    0.0,
    1.0,
    2.0
  ).set_trans(Tween.TRANS_QUART)
  
func _process(delta: float) -> void:
  _choose_cd.check(delta, false)

  if _tiles_dirty:
    _update_dirty_grid()
    _tiles_dirty = false
  
  _hovered_tile_area_highlighter.spots = []

  if not grid_cast.ray_data: return

  if grid_hovered_tile:
    var spots = []
    var ctx := EffectContext.new()
    ctx.override_location = grid_position_3d
    for effect: TileEffect in grid_hovered_tile.get_effects():
      if effect.main_target:
        spots.append_array(effect.main_target.get_target(ctx))
    _hovered_tile_area_highlighter.spots = spots

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

  DebugDraw2D.begin_text_group("-=-=-=- Grid -=-=-=-", 0, Color.AQUA)
  DebugDraw2D.set_text("hovered path", grid_hovered_tile.get_path() if grid_hovered_tile else "n/a")
  DebugDraw2D.set_text("hovered tile position", grid_position_3d)
  DebugDraw2D.set_text("hovered position", raw_pos)
  DebugDraw2D.end_text_group()
