extends Node3D
class_name BoardCamera

const MOVE_SPEED = 0.1

static var inst: BoardCamera

@onready var camera : Camera3D = $Camera3D

var _focus := Vector3.ZERO

func try_set_focus(target: Vector3) -> bool:
  _focus = target
  return true

func _ready() -> void:
  inst = self

  _focus = global_position
  
func _process(_delta: float) -> void:
  global_position = global_position.lerp(_focus, 0.1)
  
  var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down").normalized()
  _focus += Vector3(input.x, 0.0, input.y)*MOVE_SPEED
