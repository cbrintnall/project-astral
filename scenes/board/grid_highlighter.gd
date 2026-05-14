extends Node3D
class_name BoardHighlighter

const MULT = Vector3i(1, 0, 1)

static var inst: BoardHighlighter

var positive_mult_highlighter := GridHighlights.new()
var negative_mult_highlighter := GridHighlights.new()

func _ready() -> void:
  visible = true
  
  positive_mult_highlighter.mesh = load("res://assets/extracted_mesh/positive_mult_mesh.tres")
  add_child(positive_mult_highlighter)
  
  negative_mult_highlighter.mesh = load("res://assets/extracted_mesh/negative_mult_mesh.tres")
  add_child(negative_mult_highlighter)
  
  inst = self
  
  await Utils.wait_until(func(): return GridManager.inst != null)
  
  GridManager.inst.mods_changed.connect(_on_mods_changed)

func _on_mods_changed():
  var mods = GridManager.inst.get_mods()
  
  var positive_mult := []
  var negative_mult := []

  for pt in mods:
    var mod: GridContext = mods[pt]
    if mod.points_multipliers > 0.0:
      positive_mult.push_back(Vector3(pt))
    elif mod.points_multipliers < 0.0:
      negative_mult.push_back(Vector3(pt))

  positive_mult_highlighter.spots = positive_mult
  negative_mult_highlighter.spots = negative_mult
