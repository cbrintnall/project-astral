extends MarginContainer
class_name TileDataPreviewer

class TilePreviewData:
  var effects: Array
  var hide_events := false
  var context := EffectContext.new()
  var priority := 0
  var name: String
  var sub_text := ""

@onready var effects_root: Control = %EffectsDisplayRoot

var current_preview: TilePreviewData:
  get:
    if _previews:
      return _previews.front()
    return null

var _previews := []
var _preview_dirty := false
var _effect_displays := {}

func get_preview_for(effect: TileEffect):
  return _effect_displays.get(effect)

func push_preview(preview: TilePreviewData) -> Command:
  # dumb hack for tutorial
  if TutorialManager.inst.is_active() and preview.priority != -1: return
  
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
  _effect_displays = {}
  
  if current_preview:
    var used = current_preview
    %TileTitle.text = used.name
    %TileTitleSubText.text = used.sub_text
    %TileTitleSubText.visible = len(used.sub_text) > 0
    for effect in used.effects:
      var display: EffectsDisplayRoot = load("res://scenes/ui/tile_effect_display.tscn").instantiate()
      display.effect_ctx = used.context
      display.effect = effect
      display.hide_trigger = current_preview.hide_events
      _effect_displays[effect] = display
      %EffectsDisplayRoot.add_child(display)
      if effect is TileEffectGiveTile:
        var preview = load("res://scenes/ui/tile_data.tscn").instantiate()
        var data := TilePreviewData.new()
        data.effects = effect.def.effects
        data.name = effect.def.name
        data.context = EffectContext.new()
        preview.push_preview(data)
        var ctrl = Control.new()
        ctrl.add_child(preview)
        display.add_child(ctrl)
        preview.global_position = display.global_position + (Vector2.RIGHT*display.size.x)

func _process(delta: float) -> void:
  visible = current_preview != null
  
  if _preview_dirty:
    _preview_dirty = false
    _sync_displayed()
  
  if current_preview:
    current_preview.context.override_location = GridManager.inst.grid_position_3d
