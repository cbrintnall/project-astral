@tool
extends Path3D
class_name PathLine

@export var mesh: ImmediateMesh
@export var instance: MeshInstance3D
@export var width = 2.0:
  set(val):
    width = val
    _generate_mesh()
@export var sample_distance: float = 0.5:
  set(val):
    sample_distance = maxf(val, 0.1)
    _generate_mesh()

func _ready() -> void:
  curve_changed.connect(_generate_mesh)

func _process(_delta: float) -> void:
  if instance:
    instance.mesh = mesh

func _generate_mesh() -> void:
  if not mesh: return

  mesh.clear_surfaces()
  mesh.surface_begin(Mesh.PrimitiveType.PRIMITIVE_TRIANGLE_STRIP)
  
  var count := 0.0
  while count < curve.get_baked_length():
    var next_dist := minf(sample_distance, curve.get_baked_length()-count)
    
    var prev_t := curve.sample_baked_with_rotation(count)
    var curr_t := curve.sample_baked_with_rotation(count+next_dist)
    
    var prev = prev_t.origin
    var curr = curr_t.origin
    
    var prev_up = prev_t.basis.y
    var curr_up = curr_t.basis.y
    
    var prev_right = prev_t.basis.x
    var prev_left = -prev_t.basis.x
    
    var curr_right = curr_t.basis.x
    var curr_left = -curr_t.basis.x
    
    var right = (prev_right+curr_right).normalized()
    var left = (prev_left+curr_left).normalized()
  
    mesh.surface_set_normal(prev_up)
    mesh.surface_set_uv(_get_world_uv(prev+(right*width*0.5), prev_up))
    mesh.surface_add_vertex(prev+(right*width*0.5))
    
    mesh.surface_set_normal(prev_up)
    mesh.surface_set_uv(_get_world_uv(prev+(left*width*0.5), prev_up))
    mesh.surface_add_vertex(prev+(left*width*0.5))
  
    mesh.surface_set_normal(curr_up)
    mesh.surface_set_uv(_get_world_uv(curr+(right*width*0.5), curr_up))
    mesh.surface_add_vertex(curr+(right*width*0.5))
  
    mesh.surface_set_normal(curr_up)
    mesh.surface_set_uv(_get_world_uv(curr+(left*width*0.5), curr_up))
    mesh.surface_add_vertex(curr+(left*width*0.5))

    count += next_dist

  mesh.surface_end()

func _get_world_uv(pos: Vector3, norm: Vector3) -> Vector2:
  var n = norm.abs()

  if n.y > n.x and n.y > n.z:
    return Vector2(pos.x, pos.z)

  elif n.x > n.z:
    return Vector2(pos.z, pos.y)

  else:
    return Vector2(pos.x, pos.y)
