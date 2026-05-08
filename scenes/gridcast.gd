extends Node3D
class_name Gridcast

const GROUND_LAYER_BIT = 31

var ray_data := {}

var _cam: Camera3D

func _ready() -> void:
  await Utils.wait_until(func(): return GameManager.inst != null)
  
  _cam = GameManager.inst.camera

func _physics_process(_delta: float) -> void:
  var space := get_world_3d().direct_space_state
  var mouse := get_viewport().get_mouse_position()
  var origin = _cam.project_ray_origin(mouse)
  var end = origin + _cam.project_ray_normal(mouse) * 10000.0
  var query = PhysicsRayQueryParameters3D.create(origin, end)
  
  query.collide_with_bodies = true
  query.collision_mask = 1 << GROUND_LAYER_BIT

  var res = space.intersect_ray(query)
  
  ray_data = {}
  if res:
    ray_data = res
