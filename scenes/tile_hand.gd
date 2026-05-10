extends Node3D
class_name TileHand

const MAX_HAND_WIDTH = 4.0
const MAX_RANGE = [Vector3(-MAX_HAND_WIDTH, -0.7, 2.0), Vector3(MAX_HAND_WIDTH, -0.7, 2.0)]

static var inst: TileHand
static var tiles = [
  load("res://data/tiles/tile_basic_points.tres"),
  load("res://data/tiles/tile_basic_multiply_area.tres"),
  load("res://data/tiles/tile_basic_points_no_neighbors.tres"),
  load("res://data/tiles/tile_high_point_tick.tres")
]

var _markers := []

func distribute_hand():
  _create_hand()
  
func discard_hand():
  for marker in _markers:
    marker.queue_free()
    
  _markers = []
  
func _unhandled_input(event: InputEvent) -> void:
  if event is InputEventKey and event.pressed:
    if event.keycode >= KEY_0 and event.keycode <= KEY_9:
      var idx = event.keycode - KEY_0
      var visible_markers = _markers.filter(func(marker): return marker.visible)
      if idx == 0 and event.keycode == KEY_0:
        idx = 9
      else:
        idx -= 1
      if visible_markers and idx >= 0 and idx < len(visible_markers):
        var child = NodeUtils.find_child_with_predicate(visible_markers[idx], func(node): return node is Tile)
        if child:
          child.select()

func _ready() -> void:
  inst = self
  
func _create_hand():
  for i in Constants.DEFAULT_HAND_SIZE+1:
    var marker := Marker3D.new()
    add_child(marker)
    _markers.push_back(marker)
    var tile = load("res://scenes/board/tile.tscn").instantiate()
    tile.def = tiles.pick_random()
    marker.add_child(tile)
    
func _process(delta: float) -> void:  
  for marker: Marker3D in _markers:
    marker.visible = marker.get_child_count() > 0
    
  var visible_markers = _markers.filter(func(marker): return marker.visible)

  if len(visible_markers) > 1:
    for i in len(visible_markers):
      var marker: Marker3D = visible_markers[i]
      marker.position = marker.position.lerp(MAX_RANGE[0].lerp(MAX_RANGE[1], float(i)/float(len(visible_markers)-1)), 0.1)
  elif len(visible_markers) == 1:
    visible_markers[0].position = MAX_RANGE[0].lerp(MAX_RANGE[1], 0.5)
