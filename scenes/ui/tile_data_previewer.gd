extends MarginContainer
class_name TileDataPreviewer

class TilePreviewData:
  var effects: Array
  var context: EffectContext
  var priority := 0
  var name: String

@onready var effects_root: Control = %EffectsDisplayRoot

var current_preview: TilePreviewData:
  get:
    if _previews:
      return _previews.front()
    return null

var _previews := []
var _preview_dirty := false

func push_preview(preview: TilePreviewData) -> Command:
  var cmd := BasicCommand.from(
    func():
      _previews.push_back(preview)
      _preview_dirty = true,
    func():
      _previews.erase(preview)
      _preview_dirty = true
  )
  
  cmd.execute()
  
  _previews.sort_custom(
    func(a: TilePreviewData,b: TilePreviewData):
      return a.priority < b.priority
  )
  
  return cmd

func _sync_displayed():
  NodeUtils.clear_children(%EffectsDisplayRoot)
  
  if current_preview:
    var used = current_preview
    %TileTitle.text = used.name
    for effect in used.effects:
      var display: EffectsDisplayRoot = load("res://scenes/ui/tile_effect_display.tscn").instantiate()
      display.effect_ctx = used.context
      display.effect = effect
      %EffectsDisplayRoot.add_child(display)

func _process(delta: float) -> void:
  visible = current_preview != null
  
  if _preview_dirty:
    _preview_dirty = false
    _sync_displayed()
  
  if current_preview:
    current_preview.context.override_location = GridManager.inst.grid_position_3d
