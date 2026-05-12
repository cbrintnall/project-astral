extends Node3D
class_name GridHighlights

@export var mesh: Mesh
@export var spots := []

var multimesh := MultiMeshInstance3D.new()

var _mm: MultiMesh = MultiMesh.new()

func _ready() -> void:
  add_child(multimesh)
  
  multimesh.multimesh = _mm
  _mm.transform_format = MultiMesh.TRANSFORM_3D
  _mm.mesh = mesh

func _process(_delta: float) -> void:
  _mm.instance_count = maxi(len(spots), _mm.instance_count)
  _mm.visible_instance_count = len(spots)
  
  for i in len(spots):
    var t := Transform3D().translated(Vector3(spots[i]))
    _mm.set_instance_transform(i, t)
