extends Node3D
class_name BoardHighlighter

const MULT = Vector3i(1, 0, 1)

static var inst: BoardHighlighter

@onready var multi: MultiMeshInstance3D = $MultiMeshInstance3D

var highlights := {}

func highlight(pos: Vector3i, clr: Color):
  highlights[pos*MULT] = clr

func _ready() -> void:
  inst = self
  
  await Utils.wait_until(func(): return GridManager.inst != null)
  
  GridManager.inst.mods_changed.connect(_on_mods_changed)

func _on_mods_changed():
  var mods = GridManager.inst.get_mods()

  for pt in mods:
    var mod: GridContext = mods[pt]
    if mod.points_multipliers != 0.0:
      highlights[pt] = Color.WHITE
    else:
      highlights.erase(pt)

func _process(delta: float) -> void:
  multi.multimesh.visible_instance_count = len(highlights)

  var count := 0
  for pt: Vector3i in highlights:
    var t := Transform3D().translated(pt)
    multi.multimesh.set_instance_transform(count, t)
    count += 1
