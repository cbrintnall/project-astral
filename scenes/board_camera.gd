extends Node3D
class_name BoardCamera

const MOVE_SPEED = 0.1

static var inst: BoardCamera

@export var noise: FastNoiseLite

@onready var camera : Camera3D = $Camera3D

var _shake_intensity := 0.0
var _shake_remaining := 0.0
var _focus := Vector3.ZERO

func shake(amt: float, time: float):
  _shake_intensity = amt
  _shake_remaining = time

func try_set_focus(target: Vector3) -> bool:
  _focus = target
  return true

func _ready() -> void:
  inst = self

  _focus = global_position
  
func _process(delta: float) -> void:
  if _shake_remaining:
    camera.h_offset = noise.get_noise_1d(Time.get_ticks_msec()*0.09)*_shake_intensity
    camera.v_offset = noise.get_noise_1d(550.0 + (Time.get_ticks_msec()*0.09))*_shake_intensity
  else:
    camera.h_offset = 0.0
    camera.v_offset = 0.0
    
  _shake_remaining = move_toward(_shake_remaining, 0.0, delta)
  
  global_position = global_position.lerp(_focus, 0.1)
  
  var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down").normalized()
  _focus += Vector3(input.x, 0.0, input.y)*MOVE_SPEED
