extends Node3D
class_name TileHand

const HAND_BUFFER_PX = 1.0

static var inst: TileHand

var _markers: Array:
  get:
    return get_children().filter(func(child: Node): return child is Marker3D)

func get_tile_count() -> int:
  return len(_markers)
  
func discard_hand():
  for marker in _markers:
    if marker.get_child(0) is Tile:
      var tile: Tile = marker.get_child(0)
      if tile.def != null:
        HandManager.inst.return_to_discard(tile.def)
    marker.queue_free()
    
  _markers = []
  
func add_to_hand(data: TileDef):
  if len(_markers) < Constants.MAX_HAND_SIZE:
    var marker := Marker3D.new()
    add_child(marker)
    var tile = load("res://scenes/board/tile.tscn").instantiate()
    tile.def = data
    marker.add_child(tile)
  
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
  
  await Utils.wait_until(func(): return GameManager.inst != null)
  
  GameManager.inst._state.state_changed.connect(
    func(state: String):
      match state:
        "end_game":
          discard_hand()
  )
  
  await get_tree().process_frame
  
  print("tile viewport aspect: %.2f" % get_viewport().get_visible_rect().size.aspect())
    
func _process(delta: float) -> void:
  for marker: Marker3D in _markers:
    marker.visible = marker.get_child_count() > 0
    
  var visible_markers = _markers.filter(func(marker): return marker.visible)
  var bounds := (get_viewport().get_visible_rect().size.aspect() * get_viewport().get_camera_3d().size)*0.5
  var range = [Vector3(-bounds+HAND_BUFFER_PX, 0.0, 2.0), Vector3(bounds-HAND_BUFFER_PX, 0.0, 2.0)]

  if len(visible_markers) > 1:
    for i in len(visible_markers):
      var marker: Marker3D = visible_markers[i]
      marker.position = marker.position.lerp(range[0].lerp(range[1], float(i)/float(len(visible_markers)-1)), 0.1)
  elif len(visible_markers) == 1:
    visible_markers[0].position = range[0].lerp(range[1], 0.5)
