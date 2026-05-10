extends Node3D
class_name BoardCamera

const MOVE_SPEED = 0.1

static var inst: BoardCamera

@export var noise: FastNoiseLite

@onready var camera : Camera3D = $Camera3D
@onready var default_rotation := camera.rotation

var map_root: Vector3
var map_size: Vector2i
var target_fov: float = 30.0:
  set(val):
    target_fov = clampf(val, 25.0, 70.0)
  get:
    return target_fov

var _chromatic_material:ShaderMaterial = preload("res://materials/chromatic_ab_material.tres")

var _chromatic_intensity: float = .003:
  set(val):
    if _chromatic_intensity != val:
      _chromatic_intensity = val
      _chromatic_material.set_shader_parameter("strength", val)
  get:
    return _chromatic_intensity
var _shake_intensity := 0.0
var _shake_remaining := 0.0
var _focus: Vector3 = Vector3.ZERO:
  set(val):
    _focus = val
    
    var size = Vector2(map_size)*0.5
    _focus = Vector3(
      clampf(val.x, map_root.x-size.x, map_root.x+size.x),
      clampf(val.y, -INF, INF),
      clampf(val.z, map_root.z-size.y, map_root.z+size.y)
    )
  get:
    return _focus

func shake(amt: float, time: float):
  _shake_intensity = amt
  _shake_remaining = time

func try_set_focus(target: Vector3) -> bool:
  _focus = target
  return true
  
func _input(event: InputEvent) -> void:
  if event.is_action_pressed("zoom_in"):
    target_fov += 5.0
  elif event.is_action_pressed("zoom_out"):
    target_fov -= 5.0

func _ready() -> void:
  inst = self

  _focus = global_position
  
func _process(delta: float) -> void:
  var rect := get_viewport().get_visible_rect()
  var mouse := get_viewport().get_mouse_position()
  var normalized := Vector2(mouse.x/rect.size.x, mouse.y/rect.size.y)
  var offset := (normalized-Vector2(0.5, 0.5))*0.01
  
  camera.rotation = camera.rotation.lerp(default_rotation+Vector3(-offset.y, offset.x, 0.0), 0.02)      
  camera.fov = lerp(camera.fov, target_fov, 0.01)
  
  if _shake_remaining:
    camera.h_offset = noise.get_noise_1d(Time.get_ticks_msec()*0.09)*_shake_intensity
    camera.v_offset = noise.get_noise_1d(550.0 + (Time.get_ticks_msec()*0.09))*_shake_intensity
    _chromatic_intensity = .02
  else:
    camera.h_offset = 0.0
    camera.v_offset = 0.0
    _chromatic_intensity = move_toward(_chromatic_intensity, .003, .001)
    
  _shake_remaining = move_toward(_shake_remaining, 0.0, delta)
  
  global_position = global_position.lerp(_focus, 0.1)
  
  var input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
  var dir = (input.y * global_basis.z) + (input.x * global_basis.x)
  _focus += dir*MOVE_SPEED
