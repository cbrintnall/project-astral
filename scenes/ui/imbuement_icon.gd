extends MarginContainer
class_name ImbuementIcon

@export var imbuement: ImbuementDef = load("res://data/imbuements/imbuement_test.tres")

var _preview_cmd: Command
var _imbuement_selection: Selection
# We use the imbuement as a blueprint, but dupe on ready..
# this is because we want each instance of an imbuement to act individually
var _duped_imbuement: ImbuementDef

func _ready() -> void:
  var btn: Button = $Button
  var color: ColorRect = $ColorRect
  Springer.register("offset_transform_scale", color, Vector2.ONE, Vector2.ZERO, 200.0, 20.0)
  _duped_imbuement = imbuement.duplicate()
  
  btn.mouse_entered.connect(
    func(): 
      Springer.data[color]["offset_transform_scale"]["velocity"] = Vector2.ONE*10.0
      var cooldown := GameManager.inst.get_remaining_cooldown_for_imbuement(_duped_imbuement)
      var prev := TileDataPreviewer.TilePreviewData.new()
      prev.name = _duped_imbuement.name
      prev.effects = _duped_imbuement.effects
      prev.priority = 0
      if cooldown >= 0:
        prev.sub_text = "Ready To Use"
      else:
        prev.sub_text = "Ready in %s turns" % abs(cooldown)
      _preview_cmd = UI.inst.tile_previewer.push_preview(prev)
      AudioManager3d.play({
        "stream": preload("res://audio/hover-imbuement.ogg"),
        "pitch_additional": get_index()*0.01
      })
  )
  
  btn.mouse_exited.connect(
    func():
      if _preview_cmd:
        _preview_cmd.undo()
        _preview_cmd = null
  )
  
  btn.pressed.connect(_on_press)

func _on_press():
  if GameManager.inst.get_remaining_cooldown_for_imbuement(_duped_imbuement) < 0:
    AudioManager3d.play({"stream": preload("res://audio/reject.ogg")})
    return
  
  var selection := Selection.new()
  
  selection.on_process = _on_process_selection
  selection.on_choose = on_choose_selection
  selection.canceled.connect(func(): _imbuement_selection = null)
  
  if GridManager.inst.try_start_selection(selection):
    _imbuement_selection = selection
    AudioManager3d.play({"stream": preload("res://audio/select-imbuement.ogg")})

func on_choose_selection():
  var spot = GridManager.inst.grid_position_3d
  if not GridManager.inst.has_tile(spot):
    AudioManager3d.play({"stream": preload("res://audio/reject.ogg")})
    return
  
  if GameManager.inst.try_use_imbuement(_duped_imbuement, spot):
    _imbuement_selection.cancel()

func _on_process_selection(_delta: float):
  var spot = GridManager.inst.grid_position_3d
  
  var status = Selection.State.ERROR
  if GridManager.inst.has_tile(spot):
    status = Selection.State.VALID
  _imbuement_selection.state = status
