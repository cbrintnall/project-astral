extends Node
class_name GridManager

static var inst: GridManager

@export var size := Vector2i.ONE

@onready var grid_cast: Gridcast = $Gridcast

func _ready() -> void:
  inst = self
