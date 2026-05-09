extends Node3D
class_name TileHand

const MAX_HAND = 10
const MAX_HAND_WIDTH = 7.0
const MAX_RANGE = [Vector3(-MAX_HAND_WIDTH, -0.7, 2.0), Vector3(MAX_HAND_WIDTH, -0.7, 2.0)]

static var inst: TileHand
static var tiles = [
  load("res://scenes/tiles/effects/basic_destroy_tile.tscn"),
  load("res://scenes/tiles/basic_give_points_tile.tscn")
]

var _markers := []

func distribute_hand():
  _create_hand()
  
func discard_hand():
  for marker in _markers:
    marker.queue_free()
    
  _markers = []

func _ready() -> void:
  inst = self
  
func _create_hand():
  for i in MAX_HAND+1:
    var marker := Marker3D.new()
    add_child(marker)
    _markers.push_back(marker)
    var tile = tiles.pick_random().instantiate()
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
