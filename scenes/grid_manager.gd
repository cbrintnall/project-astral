extends Node
class_name GridManager

static var inst: GridManager

@export var size := Vector2i.ONE



func _ready() -> void:
  inst = self
