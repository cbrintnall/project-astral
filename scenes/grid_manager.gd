extends Node
class_name GridManager

static var inst: GridManager

@export var size := Vector2i.ONE

@onready var grid_map: GridMap = $GridMap
@onready var grid_cast: Gridcast = $Gridcast
@onready var selection: Node3D = $SelectionBox

var grid_position_3d: Vector3i

var _choose_cd := BetterTimer.new(0.1)
var _current_selection: Selection
var _placements := {}

func try_place_tile(tile: Tile, pos: Vector3i) -> bool:
  if _placements.has(pos): return false
  
  _placements[pos] = tile
  tile.reparent(grid_map)
  tile.global_position = pos
  
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
  
func _unhandled_input(event: InputEvent) -> void:
  if event.is_action_pressed("ui_cancel"):
    _cancel_current_selection()
    
  # timer cooldown so we don't immediately do something after creating selection
  # everything below this if statement should be selection related
  if _choose_cd.progress < 1.0: return
    
  if event is InputEventMouseButton:
    if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
      if _current_selection and _current_selection.on_choose.is_valid():
        _current_selection.on_choose.call()
      
func _cancel_current_selection():
  if _current_selection:
    if _current_selection.can_cancel:
      _current_selection.cancel()
      _current_selection = null

func _ready() -> void:
  inst = self
  
func _process(delta: float) -> void:
  _choose_cd.check(delta, false)
  var grid_pos: Vector3 = grid_cast.ray_data["position"]
  var raw_pos = grid_pos+grid_pos.sign()*0.5
  var raw_tile = Vector3i(raw_pos)
  grid_position_3d = grid_map.to_global(grid_map.map_to_local(raw_tile))
  selection.global_position = grid_position_3d
  selection.visible = _current_selection != null

  DebugDraw2D.set_text("hovered tile", grid_position_3d)
  DebugDraw2D.set_text("hovered position", raw_pos)
