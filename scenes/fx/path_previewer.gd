extends Path3D
class_name PathPreviewer

@export var speed := 10.0

@onready var follower: PathFollow3D = $PathFollow3D

func _ready() -> void:
  curve = Curve3D.new()
  curve.add_point(Vector3.ZERO)
  curve.add_point(Vector3.ZERO)

func _process(delta: float) -> void:
  follower.progress += delta*speed
