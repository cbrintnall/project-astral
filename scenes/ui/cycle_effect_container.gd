extends MarginContainer
class_name CycleEffectContainer

var effect: TileEffect

var _hover_cmd : Command
var _tooltip_cmd : Command

func _ready() -> void:
  $Button.mouse_entered.connect(_mouse_entered.bind(true))
  $Button.mouse_exited.connect(_mouse_entered.bind(false))

func _mouse_entered(state: bool):
  if state:
    var prev := TileDataPreviewer.TilePreviewData.new()
    prev.effects=[effect]
    _hover_cmd=UI.inst.tile_previewer.push_preview(prev)
    _tooltip_cmd = UI.inst.show_tooltip("Cycle events are triggered off your actions and events.")
  else:
    if _hover_cmd:
      _hover_cmd.undo()
      _hover_cmd = null
    if _tooltip_cmd:
      _tooltip_cmd.undo()
      _tooltip_cmd = null
      
func _exit_tree() -> void:
  if _hover_cmd:
    _hover_cmd.undo()
    _hover_cmd = null
  if _tooltip_cmd:
    _tooltip_cmd.undo()
    _tooltip_cmd = null

func _process(delta: float) -> void:
  var time := Time.get_ticks_msec()*0.003
  offset_transform_position = Vector2(cos(time+global_position.x),sin(time+global_position.x))*3.0
