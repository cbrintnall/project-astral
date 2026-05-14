extends MarginContainer
class_name TileUIPreview

@onready var button = $Button

var tile: TileDef:
  set(val):
    tile = val
    
    if tile:
      %TileIcon.texture = tile.texture
  get:
    return tile
    
var _preview_command: Command
    
func _ready() -> void:
  button.mouse_entered.connect(_handle_display.bind(true))
  button.mouse_exited.connect(_handle_display.bind(false))
    
func _handle_display(state: bool):
  if state:
    assert(_preview_command == null)
    var preview := TileDataPreviewer.TilePreviewData.new()
    preview.name = tile.name
    preview.effects = tile.effects
    preview.context = EffectContext.new()
    preview.priority = 0
    _preview_command = UI.inst.tile_previewer.push_preview(preview)
  else:
    assert(_preview_command != null)
    _preview_command.undo()
    _preview_command = null
    
func _process(delta: float) -> void:
  if tile == null:
    queue_free()
    set_process(false)
    return
  
  if NodeUtils.is_mouse_inside(button):
    var amt = (sin(Time.get_ticks_msec()*0.003)+1.0)*0.5
    
    %TileIcon.offset_transform_position = Vector2.UP*amt*5.0
    %TileIcon.offset_transform_scale = %TileIcon.offset_transform_scale.move_toward(Vector2(1.1, 1.1), delta)
  else:
    %TileIcon.offset_transform_position = %TileIcon.offset_transform_position.move_toward(Vector2.ZERO, delta)
    %TileIcon.offset_transform_scale = %TileIcon.offset_transform_scale.move_toward(Vector2.ONE, delta)
