extends StaticBody3D
class_name TilePack

@export var stretcher: Stretcher3D

var tiles := []
var cost := 0

var _hover_cmd : Command

func _ready() -> void:
  cost = roundi(lerp(3.0, 10.0, randfn(0.2, 0.1)))
  
  for i in 3:
    tiles.push_back(
      AllTileContainer.inst.resources.filter(func(tile: TileDef): return tile.in_shop).pick_random()
    )

func _mouse_enter() -> void:
  if get_viewport().gui_get_hovered_control() != null: return
  stretcher.punch(3.0,5.0)
  _hover_cmd=UI.inst.show_tooltip("Purchase a pack of 3 random tiles.")

func _mouse_exit() -> void:
  if _hover_cmd:
    _hover_cmd.undo()
  
func _exit_tree() -> void:
  if _hover_cmd:
    _hover_cmd.undo()

func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
  if get_viewport().gui_get_hovered_control() != null: return
  
  if event is InputEventMouseButton:
    if event.is_pressed():
      if event.button_index == MOUSE_BUTTON_LEFT:
        _try_purchase()
        
func _try_purchase():
  if GameManager.inst.money >= cost:
    GameManager.inst.money -= cost
    for tile in tiles:
      HandManager.inst.add_tile(tile)
    queue_free()
  else:
    AudioManager3d.play({"stream": preload("res://audio/reject.ogg")})
