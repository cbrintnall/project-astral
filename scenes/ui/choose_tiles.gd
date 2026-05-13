extends MarginContainer
class_name ChooseTilesUI

@onready var submit : Button = %SelectionSubmit
@onready var options_root = %Options
@onready var selection_root = %Selections

var open := false

func _ready() -> void:
  submit.pressed.connect(_on_submit)
  offset_top = get_viewport().get_visible_rect().size.y + size.y

func setup():
  NodeUtils.clear_children(options_root)
  NodeUtils.clear_children(selection_root)

  var options = AllTileContainer.inst.resources.filter(func(tile): return tile.in_shop)
  for i in Constants.TILE_OPTIONS_PER_TURN:
    var opt: TileDef = options.pick_random()
    var preview: TileUIPreview = load("res://scenes/ui/tile_preview.tscn").instantiate()
    
    preview.tile = opt
    options_root.add_child(preview)
    preview.button.pressed.connect(_chose_prev.bind(preview))
    
  open = true

func _on_submit():
  for child in selection_root.get_children():
    HandManager.inst.add_tile(child.tile)
  open = false

func _chose_prev(prev: TileUIPreview):
  if prev.get_parent() == options_root:
    if selection_root.get_child_count() < Constants.TILE_OPTIONS_ALLOWED_SELECTIONS:
      prev.reparent(selection_root)
  elif prev.get_parent() == selection_root:
    prev.reparent(options_root)

func _process(delta: float) -> void:
  var offset := 0.0 if open else get_viewport().get_visible_rect().size.y + size.y
  offset_top = lerp(offset_top, offset, 0.1)
