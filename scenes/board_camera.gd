extends Node3D
class_name BoardCamera

const MOVE_SPEED = 0.1

static var inst: BoardCamera

@export var noise: FastNoiseLite

@onready var camera : Camera3D = $Camera3D
@onready var default_rotation := camera.rotation

var _shake_intensity := 0.0
var _shake_remaining := 0.0
var _focus: Vector3 = Vector3.ZERO:
  set(val):
    _focus = val
    
    var size = Vector2(GridManager.inst.size)*0.5
    _focus = Vector3(
      clampf(val.x, -size.x, size.x),
      clampf(val.y, -INF, INF),
      clampf(val.z, -size.y, size.y)
    )
  get:
    return _focus

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
  var rect := get_viewport().get_visible_rect()
  var mouse := get_viewport().get_mouse_position()
  var normalized := Vector2(mouse.x/rect.size.x, mouse.y/rect.size.y)
  var offset := (normalized-Vector2(0.5, 0.5))*0.01
  
  camera.rotation = camera.rotation.lerp(default_rotation+Vector3(-offset.y, offset.x, 0.0), 0.02)
  
  if _shake_remaining:
    camera.h_offset = noise.get_noise_1d(Time.get_ticks_msec()*0.09)*_shake_intensity
    camera.v_offset = noise.get_noise_1d(550.0 + (Time.get_ticks_msec()*0.09))*_shake_intensity
  else:
    camera.h_offset = 0.0
    camera.v_offset = 0.0
    
  _shake_remaining = move_toward(_shake_remaining, 0.0, delta)
  
  global_position = global_position.lerp(_focus, 0.1)
  
  var input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
  var dir = (input.y * global_basis.z) + (input.x * global_basis.x)
  _focus += dir*MOVE_SPEED
