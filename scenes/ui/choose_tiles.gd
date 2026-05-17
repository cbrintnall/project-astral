extends MarginContainer
class_name ChooseTilesUI

signal tile_selected(tile: TileDef)
signal canceled

@onready var submit : Button = %SelectionSubmit
@onready var selection_root = %Selections

var open := false

func _ready() -> void:
  submit.pressed.connect(_on_submit)
  offset_top = get_viewport().get_visible_rect().size.y + size.y

func show_tiles(tiles: Array, title: String):
  open = true
  %ChooseTitle.text = title
  NodeUtils.clear_children(selection_root)
  for tile: TileDef in tiles:
    var preview: TileUIPreview = load("res://scenes/ui/tile_preview.tscn").instantiate()
    
    preview.tile = tile
    selection_root.add_child(preview)
    preview.button.pressed.connect(tile_selected.emit.bind(tile))

func _on_submit():
  open = false
  canceled.emit()

func _process(delta: float) -> void:
  var offset := 0.0 if open else get_viewport().get_visible_rect().size.y + size.y
  offset_top = lerp(offset_top, offset, 0.1)
