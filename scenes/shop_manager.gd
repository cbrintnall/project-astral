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
    
  for child in displays_parent.get_children():
    if child is ShopOption:
      child.generate()
