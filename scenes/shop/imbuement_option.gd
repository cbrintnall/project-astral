extends StaticBody3D
class_name ImbuementOption

@onready var stretcher = $Stretcher3D

var cost: int
var effect: TileEffect

var _hovered_cmd : Command
var _hovered_prev_cmd: Command
var _tile_selection: Selection
var _entered := false

func _ready() -> void:
  cost = roundi(lerp(1.0, 10.0, randfn(0.2, 0.1)))
  effect = RealImbuementContainer.inst.resources.pick_random().clone()

func _mouse_enter() -> void:
  if get_viewport().gui_get_hovered_control() != null: return
  
  _entered = true
  
  stretcher.punch(3.0,5.0)
  
  AudioManager3d.play({
    "stream": preload("res://audio/glass-hover.ogg"),
    "pitch_variance": 0.1,
    "parent": self
  })
  
  _hovered_cmd = UI.inst.show_tooltip("Purchase an imbuement")
  
  var prev := TileDataPreviewer.TilePreviewData.new()
  prev.effects = [effect]
  prev.name = "Blessing"
  prev.sub_text = "Added to the tile of\nyour choice"
  
  _hovered_prev_cmd=UI.inst.tile_previewer.push_preview(prev)
  
func _mouse_exit() -> void:
  _entered = false
  
  if _hovered_cmd:
    _hovered_cmd.undo()
    _hovered_cmd = null
  
  if _hovered_prev_cmd:
    _hovered_prev_cmd.undo()
    _hovered_prev_cmd = null
  
func _exit_tree() -> void:
  if _hovered_cmd:
    _hovered_cmd.undo()
    _hovered_cmd = null
  
  if _hovered_prev_cmd:
    _hovered_prev_cmd.undo()
    _hovered_prev_cmd = null
  
func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
  if get_viewport().gui_get_hovered_control() != null: return
  
  if UIUtils.is_click(event, MOUSE_BUTTON_LEFT):
    if GameManager.inst.money < cost:
      AudioManager3d.play({
        "stream": preload("res://audio/reject.ogg"),
        "pitch_variance": 0.1
      })
      return

    var selection := Selection.new()
    selection.canceled.connect(
      func():
        UI.inst.choose_tiles.open = false
        var chooser: ChooseTilesUI = UI.inst.choose_tiles
        if chooser.canceled.is_connected(_tile_selection.cancel):
          chooser.canceled.disconnect(_tile_selection.cancel)
        if chooser.tile_selected.is_connected(_on_choose_tile):
          chooser.tile_selected.disconnect(_on_choose_tile)
        _tile_selection = null
    )

    if GridManager.inst.try_start_selection(selection):
      _tile_selection = selection
      var chooser: ChooseTilesUI = UI.inst.choose_tiles
      chooser.show_tiles(HandManager.inst.all_tiles, "Choose 1 to bless")
      chooser.canceled.connect(_tile_selection.cancel, CONNECT_ONE_SHOT)
      chooser.tile_selected.connect(_on_choose_tile, CONNECT_ONE_SHOT)
    else:
      AudioManager3d.play({
        "stream": preload("res://audio/reject.ogg"),
        "pitch_variance": 0.1
      })

func _process(delta: float) -> void:
  if _entered:
    stretcher.position = stretcher.position.lerp(Vector3.UP, 0.1)
  else:
    stretcher.position = stretcher.position.lerp(Vector3.ZERO, 0.01)
      
func _on_choose_tile(tile: TileDef):
  GameManager.inst.money -= cost
  _tile_selection.cancel()
  tile.effects.push_back(effect)
  queue_free()
