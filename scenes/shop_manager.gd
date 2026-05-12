extends Node
class_name ShopManager

static var inst: ShopManager

@onready var root : Node3D = $Root
@onready var bounds: Node3D = $Root/ShopBounds
@onready var displays_parent = $Root/DisplayOptions

@export var size: Vector2i

func _ready() -> void:
  inst = self
  bounds.scale = Vector3(size.x, size.x*0.25, size.y)

func enter():
  BoardCamera.inst.map_root = root.global_position
  BoardCamera.inst.map_size = size
  BoardCamera.inst.try_set_focus(root.global_position)
  
  var corrected_position = Vector3(root.global_position.x, root.global_position.z, 0.0)
  print("updating grid root to %s" % str(corrected_position))
  RenderingServer.global_shader_parameter_set("grid_root", corrected_position)
    
  for child in displays_parent.get_children():
    if child is ShopOption:
      child.generate()
