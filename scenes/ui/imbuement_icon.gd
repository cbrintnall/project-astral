extends MarginContainer
class_name ImbuementIcon

var imbuement: ImbuementDef:
  get:
    return HandManager.inst.get_imbuement_at_idx(get_index())

var _preview_cmd: Command
var _imbuement_selection: Selection

func _ready() -> void:
  var btn: Button = $Button
  var icon: TextureRect = %Icon
  Springer.register("offset_transform_scale", icon, Vector2.ONE*2.0, Vector2.ZERO, 200.0, 20.0)

  btn.mouse_entered.connect(
    func(): 
      if not imbuement: return
      
      Springer.data[icon]["offset_transform_scale"]["velocity"] = Vector2.ONE*10.0
      var cooldown := GameManager.inst.get_remaining_cooldown_for_imbuement(imbuement)
      var prev := TileDataPreviewer.TilePreviewData.new()
      prev.name = imbuement.name
      prev.effects = imbuement.effects
      prev.priority = 0
      prev.hide_events = true
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
  
func _process(_delta: float) -> void:
  %Icon.visible = imbuement != null
  %CooldownRemaining.visible = imbuement != null 
  
  if not imbuement:
    return

  var remaining_cd = abs(GameManager.inst.get_remaining_cooldown_for_imbuement(imbuement))
  %Icon.texture = imbuement.icon
  %CooldownRemaining.visible = remaining_cd > 0
  %CooldownRemaining.text = str(remaining_cd)
  %Icon.set_instance_shader_parameter("progress", 1.0-(float(remaining_cd)/float(imbuement.turn_cooldown)))

func _on_press():
  if not imbuement: return
  
  if GameManager.inst.get_remaining_cooldown_for_imbuement(imbuement) < 0:
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
  
  if GameManager.inst.try_use_imbuement(imbuement, spot):
    _imbuement_selection.cancel()

func _on_process_selection(_delta: float):
  var spot = GridManager.inst.grid_position_3d
  
  var status = Selection.State.ERROR
  if GridManager.inst.has_tile(spot):
    status = Selection.State.VALID
  _imbuement_selection.state = status
