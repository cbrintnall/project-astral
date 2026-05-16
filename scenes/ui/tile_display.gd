extends MarginContainer
class_name TileDisplay

signal toggled

@export var title := ""
@export var deck: HandManager.Deck

var _tile_previews := []
var _tile_display_offset := 0.0
var _tile_display_open := false

func _ready() -> void:
  %HandTitle.text = title
  offset_transform_enabled = true
  _tile_display_offset = size.y
  %ToggleTileDisplay.pressed.connect(func(): _tile_display_open = not _tile_display_open)

func _process(_delta: float) -> void:
  %OpenToggle.global_position = (%ToggleAnchor.global_position - %OpenToggle.get_combined_pivot_offset()) + (Vector2.UP * 32.0)
  %OpenToggle.offset_transform_enabled = true
  %HandTitle.reset_size()
  %HandTitle.global_position = NodeUtils.get_anchored_position(%OpenToggle, Vector2(0.5, 0.0)) - %HandTitle.get_combined_pivot_offset()
  %QuantityText.text = str(HandManager.inst.get_deck_size(deck))

  #if NodeUtils.is_mouse_inside(%OpenToggle):
    #%OpenToggle.offset_transform_position = lerp(Vector2.ZERO, Vector2.UP*32.0, sin(Time.get_ticks_msec()*0.003))
  
  if _tile_display_open:
    offset_transform_position = offset_transform_position.lerp(Vector2.ZERO, 0.1)
  else:
    offset_transform_position = offset_transform_position.lerp(Vector2(0.0, size.y-2.0), 0.05)
  
  var deck_size = HandManager.inst.get_deck_size(deck)
  var missing_previews = deck_size-len(_tile_previews)

  for i in missing_previews:
    var next = load("res://scenes/ui/tile_preview.tscn").instantiate()
    %TilePreviewRoot.add_child(next)
    next.tree_exiting.connect(func(): _tile_previews.erase(next))
    _tile_previews.push_back(next)

  for i in len(_tile_previews):
    var preview: TileUIPreview = _tile_previews[i]
    preview.tile = HandManager.inst.get_tile_at_idx(deck, i)
  
