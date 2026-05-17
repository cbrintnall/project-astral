extends StaticBody3D
class_name RemovalAnvil

@onready var hammer_rest_transform: Marker3D = $HammerRestTransform
@onready var hammer_ready_transform: Marker3D = $HammerReadyTransform
@onready var hammer_smash_transform: Marker3D = $HammerSmashTransform
@onready var hammer_prepare_transform: Marker3D = $HammerPrepareTransform
@onready var tile_marker: Marker3D = $Stretcher3D/vfxAnvil/TileMarker
@onready var label: Label3D = $ShopLabel

@onready var hammer: Node3D = $vfxHammer

@export var noise_offset : FastNoiseLite

var current_cost := 0

var _entered := false
var _working := false
var _tile_selection : Selection
var _removal : TileDef
var _hover_cmd:Command

func _ready() -> void:
  await Utils.wait_until(func(): return ShopManager.inst != null)
  
  ShopManager.inst.entered.connect(
    func():
      current_cost = 2
  )
  
  Springer.register("global_position", label, label.global_position, Vector3.ZERO, 200.0, 10.0)

func _mouse_enter() -> void:
  if get_viewport().gui_get_hovered_control() != null: return

  _entered = true
  _hover_cmd=UI.inst.show_tooltip("Remove a tile")
  
func _mouse_exit() -> void:
  _entered = false
  _hover_cmd.undo()
  
func _process(_delta: float) -> void:
  label.text = str(current_cost)
  
  if _working: return
  
  var target = hammer_ready_transform if (_entered or _tile_selection != null) else hammer_rest_transform
  var basis_target = target.global_transform
  
  hammer.global_transform = hammer.global_transform.interpolate_with(basis_target, 0.05)
  
  if _entered:
    hammer.position += lerp(0.0, 0.002, sin(Time.get_ticks_msec()*0.003)) * Vector3.UP
  
func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
  if get_viewport().gui_get_hovered_control() != null: return
  
  if UIUtils.is_click(event, MOUSE_BUTTON_LEFT) and not _working:
    if len(HandManager.inst.all_tiles) <= 1:
      AudioManager3d.play({
        "stream": preload("res://audio/reject.ogg"),
        "pitch_variance": 0.1
      })
      return
    if GameManager.inst.money < current_cost:
      AudioManager3d.play({
        "stream": preload("res://audio/reject.ogg"),
        "pitch_variance": 0.1
      })
      Springer.data[label]["global_position"]["velocity"] += [-label.global_basis.x,label.global_basis.x].pick_random()*5.0
      return
    
    var selection := Selection.new()
    selection.canceled.connect(
      func():
        _tile_selection = null
        UI.inst.choose_tiles.open = false
    )

    if GridManager.inst.try_start_selection(selection):
      _tile_selection = selection
      var chooser: ChooseTilesUI = UI.inst.choose_tiles
      chooser.show_tiles(HandManager.inst.all_tiles, "Choose 1 to remove")
      chooser.canceled.connect(_tile_selection.cancel, CONNECT_ONE_SHOT)
      chooser.tile_selected.connect(
        func(tile: TileDef):
          GameManager.inst.money -= current_cost
          _removal = tile
          _tile_selection.cancel()
          _working = true
          HandManager.inst.remove_tile(tile)
          var tile_display: Tile = load("res://scenes/board/tile.tscn").instantiate()
          tile_display.def = tile
          tile_marker.add_child(tile_display)
          tile_display.set_display_mode()
          await _do_removal(
            func():
              tile_display.queue_free()
              Springer.data[label]["global_position"]["velocity"] += Vector3.UP*10.0
          )
          _working = false
          _removal = null
          current_cost += 2,
        CONNECT_ONE_SHOT
      )

func _do_removal(on_hit: Callable):
  var t = create_tween()

  t.tween_method(
    func(time: float):
      hammer.global_transform = hammer_ready_transform.global_transform.interpolate_with(
        hammer_prepare_transform.global_transform, 
        time
      )
      hammer.position += noise_offset.get_noise_1d(time)*hammer.global_basis.x
      ,
    0.0,
    1.0,
    0.7
  ).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
  
  var final_step := t.tween_method(
    func(time: float):
      hammer.global_transform = hammer_prepare_transform.global_transform.interpolate_with(
        hammer_smash_transform.global_transform, 
        pow(time, 3.0)
      ),
    0.0,
    1.0,
    0.3
  ).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
  
  final_step.finished.connect(
    func():
      BoardCamera.inst.shake(0.2, 0.1)
      AudioManager3d.play({
        "stream": preload("res://audio/anvil-hit.wav"),
        "location": hammer.global_position
      })
      on_hit.call()
  )
  
  t.tween_interval(0.1)
  
  await t.finished
