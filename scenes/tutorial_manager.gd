extends Node
class_name TutorialManager

static var inst: TutorialManager

@export var cycle: Control
@export var turn: Control
@export var money: Control
@export var score: Control
@export var cycle_effects: Control
@export var play_button: Control
@export var deck: Control

@onready var rect: ReferenceRect = $ReferenceRect
@onready var btn: Button = $ReferenceRect/Button
@onready var canvas: CanvasLayer = $CanvasLayer

var _state := CallableStateMachine.new()
var _idx := -1
var _order = [
  "cycle",
  "turn",
  "money",
  "score",
  "example",
  "effect1",
  "effect2",
  "effect3",
  "area",
  "removal",
  "deck",
  "final",
  "done"
]

var _tile_prev_cmd: Command
var _display_tile: Tile

func is_active() -> bool:
  return _state.current != "done"

func skip():
  _state.current = "done"

func _ready() -> void:
  inst = self
  
  add_child(_state)
  
  btn.pressed.connect(_on_press)
  
  _state.register("init", CallableStateMachine.noop)
  
  for entry in _order:
    _state.register(entry, CallableStateMachine.noop)
  
  _on_press()
  _state.state_changed.connect(_on_state_changed)
  
  _highlight(cycle)
  
func _on_state_changed(state: String):
  print("new tutorial state: %s" % state)
  
  match state:
    "cycle":
      _highlight(cycle)
      %TutorialText.text = "You are trying to survive Nyx's relentless fight, to win, reach the final cycle."
      %TutorialText.reset_size()
    "turn":
      _highlight(turn)
      %TutorialText.text = "A cycle consists of three turns, even if you beat the score. At the start of each cycle (including after the tutorial) you'll visit the shop where you can purchase various goods."
      %TutorialText.reset_size()
    "money":
      _highlight(money)
      %TutorialText.text = "Each turn you beat the score requirement, you earn money. Alongside other methods. Here is some money to start."
    "score":
      _highlight(score)
      %TutorialText.text = "This is your current score / target."
    "example":
      var tile: Tile = load("res://scenes/board/tile.tscn").instantiate()
      tile.def = load("res://data/tiles/tile_basic_points.tres")
      GridManager.inst.try_place_tile(tile, Vector3i(2, 0, 0))
      await get_tree().process_frame
      assert(BoardCamera.inst.try_set_focus(GridManager.inst.get_tile_loc(tile)))
      var prev = TileDataPreviewer.TilePreviewData.new()
      prev.effects = tile.get_effects()
      prev.name = tile.get_tile_name()
      prev.sub_text = "Tutorial Use Only"
      prev.priority = -1
      _tile_prev_cmd=UI.inst.tile_previewer.push_preview(prev)
      %TutorialText.text = "To earn score, you'll place tiles."
    "effect1":
      var prev = UI.inst.tile_previewer.get_preview_for(GridManager.inst.get_tile_at(Vector3i(2, 0, 0)).get_effects()[0])
      _highlight(prev)
      %TutorialText.text = "Tiles have effects that trigger off certain actions. This gives you 5 points when you place the tile."
    "effect2":
      var prev = UI.inst.tile_previewer.get_preview_for(GridManager.inst.get_tile_at(Vector3i(2, 0, 0)).get_effects()[1])
      _highlight(prev)
      %TutorialText.text = "And then 5 more once the round ends. Tiles stay on the board until destroyed, either by their health reaching 0 or other means."
    "effect3":
      var tile: Tile = GridManager.inst.get_tile_at(Vector3i(2, 0, 0))
      var added = TileEffectChip.new()
      var target = TileTargetDef.new()
      target.column = true
      target.size = Vector2i(5,5)
      target.include_self = false
      added.main_target = target
      tile.register_effect(added)
      var prev = TileDataPreviewer.TilePreviewData.new()
      prev.effects = tile.get_effects()
      prev.name = tile.get_tile_name()
      prev.sub_text = "Tutorial Use Only"
      prev.priority = -1
      rect.reparent(self)
      await get_tree().process_frame
      _tile_prev_cmd.undo()
      _tile_prev_cmd=UI.inst.tile_previewer.push_preview(prev)
      await get_tree().process_frame
      _highlight(UI.inst.tile_previewer.get_preview_for(tile.get_effects()[2]))
      %TutorialText.text = "Tiles can have effects added to them in the shop (or by other tiles)."
    "area":
      var tile: Tile = GridManager.inst.get_tile_at(Vector3i(2, 0, 0))
      var effect: EffectsDisplayRoot = UI.inst.tile_previewer.get_preview_for(tile.get_effects()[2])
      _highlight(effect.area_tags.get_child(0))
      %TutorialText.text = "These tell you where this will which tiles are effected (often referred to as marked)."
    "removal":
      _highlight(deck)
      GridManager.inst.get_tile_at(Vector3i(2, 0, 0)).destroy()
      GameManager.inst.point_source.current = 0
      _tile_prev_cmd.undo()
      _tile_prev_cmd = null
      _idx += 1
      _state.current = _order[_idx]
    "deck":
      _highlight(deck)
      %TutorialText.text = "After the tutorial (done soon) tiles will appear here to play."
    "final":
      %TutorialText.text = "Each cycle you will have to fight against Nyx, who will attack in various ways. Good luck!"
    "done":
      GameManager.inst.on_tutorial_finished()
      rect.queue_free()
      var t = create_tween()
      t.tween_property(
        canvas,
        "offset",
        Vector2.DOWN*get_viewport().get_visible_rect().size,
        1.0
      ).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
      t.finished.connect(canvas.queue_free)
      set_process(false)
  
func _on_press():
  AudioManager3d.play({
    "stream": preload("res://audio/healed.ogg"),
    "pitch_variance": 0.1
  })
  _idx += 1
  _state.current = _order[_idx]

func _process(delta: float) -> void:
  if not rect: return
  rect.offset_transform_scale = Vector2.ONE.lerp(Vector2.ONE*1.1, (sin(Time.get_ticks_msec()*0.003) + 1.0) * 0.5)
  rect.position = rect.position.lerp(Vector2.ZERO, 0.1)

func _highlight(ctrl: Control):
  rect.reparent(ctrl, true)
  rect.anchor_bottom = 1.0
  rect.anchor_right = 1.0
