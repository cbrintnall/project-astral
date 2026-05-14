extends MarginContainer
class_name TileDisplay

signal toggled

@export var category := ""
@export var deck: HandManager.Deck

var _tile_previews := []
var _tile_display_offset := 0.0
var _tile_display_open := false

func _ready() -> void:
  _tile_display_offset = size.y
  %ToggleTileDisplay.text = "Toggle %s" % category
  %ToggleTileDisplay.pressed.connect(func(): _tile_display_open = not _tile_display_open)

func _process(delta: float) -> void:
  if _tile_display_open:
    anchor_top = lerp(anchor_top, 0.2, 0.1)
  else:
    anchor_top = lerp(anchor_top, 1.0, 0.1)
  
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
  
