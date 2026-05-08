extends StaticBody3D
class_name Tile

@onready var mesh: MeshInstance3D = $Stretcher3D/MeshInstance3D
@onready var stretcher: Stretcher3D = $Stretcher3D

@onready var rotation_axis := Vector3(randf(), randf(), randf()).normalized()

var _state := CallableStateMachine.new()
var _mouse_entered := false

func unselect():
  if _state.current == "placing":
    _state.current = "selecting"
    AudioManager3d.play({ "stream": preload("res://audio/Light Drone Sound (button hover) 9.wav"), "pitch_additional": -0.1 })

func _ready() -> void:
  add_child(_state)
  add_to_group("tile")
  
  _state.register("selecting", _selecting)
  _state.register("placing", _placing)

func _selecting(machine: CallableStateMachine, delta: float):
  mesh.rotate(rotation_axis, delta)
  position = position.lerp(Vector3.ZERO, delta*10.0)

func _placing(machine: CallableStateMachine, delta: float):
  mesh.rotate(rotation_axis, delta*0.25)
  position = position.lerp(Vector3.UP, delta*10.0)

func _mouse_enter() -> void:
  _mouse_entered = true
  stretcher.punch(1.0, 3.0)
  AudioManager3d.play({
    "stream": preload("res://audio/hover-stone.ogg"),
    "pitch_variance": 0.1
  })
  
func _mouse_exit() -> void:
  _mouse_entered = false
  
func _on_select():
  match _state.current:
    "selecting":
      stretcher.punch(3.0, 5.0)
      for tile: Tile in get_tree().get_nodes_in_group("tile"):
        tile.unselect()
      _state.current = "placing"
      AudioManager3d.play({ "stream": preload("res://audio/Light Drone Sound (button hover) 9.wav") })
    "placing":
      unselect()

func _unhandled_input(event: InputEvent) -> void:
  if _state.current == "placing" and event.is_action_pressed("ui_cancel"):
    unselect()
  
  if not _mouse_entered: return
  
  if event is InputEventMouseButton:
    if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
      _on_select()
