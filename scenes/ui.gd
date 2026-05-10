extends CanvasLayer
class_name UI

static var inst: UI

@onready var score_label: Label = %ScoreLabel
@onready var turn_label: Label = %TurnLabel
@onready var cycle_label: Label = %CycleLabel
@onready var help: Control = $Help
@onready var system_label: RichTextLabel = %SystemMessage

var displayed_tile: Tile
var displayed_context: EffectContext

func show_system_message(text: String, audio: AudioStream = null):
  system_label.text = text

  var t = create_tween()
  t.tween_property(
    system_label,
    "self_modulate",
    Color.WHITE,
    0.5
  ).set_trans(Tween.TRANS_CUBIC)
  t.tween_interval(3.0)
  t.tween_property(
    system_label,
    "self_modulate",
    Color.TRANSPARENT,
    1.0
  ).set_trans(Tween.TRANS_CUBIC)

func _ready() -> void:
  inst = self
  
  system_label.self_modulate = Color.TRANSPARENT

  %PlayButton.pressed.connect(
    func():
      match GameManager.inst.current_state:
        "shop":
          GameManager.inst.leave_shop()
        "wait_for_player":
          GameManager.inst.try_execute_turn()
        "wait_for_accept_shop":
          GameManager.inst.enter_shop()
  )
  
  %HelpButton.pressed.connect(
    func():
      help.visible = not help.visible
  )
  
  Springer.register("offset_transform_position", score_label, Vector2.ZERO, Vector2.ZERO, 200.0, 10.0)
  Springer.register("offset_transform_scale", score_label, Vector2.ONE, Vector2.ZERO, 200.0, 10.0)
  
  await Utils.wait_until(func(): return GameManager.inst != null)
  
  GameManager.inst.points_fx.connect(
    func():
      score_label.offset_transform_position = Utils.random_unit_circle()*5.0
      score_label.offset_transform_scale = Vector2(randf_range(1.0, 1.2), randf_range(1.0, 1.2))
  )
  
func _unhandled_input(event: InputEvent) -> void:
  if event.is_action_pressed("ui_cancel"):
    help.visible = false

func _sync_displayed():
  NodeUtils.clear_children(%EffectsDisplayRoot)
  
  if displayed_tile:
    %TileTitle.text = displayed_tile.def.name
    displayed_context = EffectContext.new()
    displayed_context.tile = displayed_tile
    for effect in displayed_tile.get_effects():
      var display: EffectsDisplayRoot = load("res://scenes/ui/tile_effect_display.tscn").instantiate()
      %EffectsDisplayRoot.add_child(display)
      display.effect_ctx = displayed_context
      display.effect = effect

func _process(_delta: float) -> void:
  score_label.text = "%d/%d" % [ GameManager.inst.current_score, GameManager.inst.required_score ]
  turn_label.text = "Turn: %d/%d" % [ GameManager.inst.turn, Constants.TURNS_PER_SCORE ]
  cycle_label.text = "Cycle: %d" % [ GameManager.inst.cycle ]
  %MoneyLabel.text = "Money: %d" % [ GameManager.inst.money ]
  
  %TileData.visible = displayed_tile != null
  %PlayButton.disabled = GameManager.inst.active_execution and GameManager.inst.active_execution.active_round
  
  var play_text := "Play"
  
  match GameManager.inst.current_state:
    "shop":
      play_text = "Leave"
    "wait_for_accept_shop":
      play_text = "Next"
      
  %PlayText.text = play_text

  var desired_display: Tile = null
  
  if GameManager.inst.active_execution and GameManager.inst.active_execution.active_round:
    var queue = GameManager.inst.get_current_execution_queue()
    if queue and is_instance_valid(queue.front()):
      desired_display = queue.front()
  if GridManager.inst.hand_hovered_tile:
    desired_display = GridManager.inst.hand_hovered_tile
  elif GridManager.inst.grid_hovered_tile:
    desired_display = GridManager.inst.grid_hovered_tile
  elif GridManager.inst.hand_selected_tile:
    desired_display = GridManager.inst.hand_selected_tile

  if displayed_context:
    displayed_context.override_location = GridManager.inst.grid_position_3d

  if not displayed_tile:
    if desired_display:
      displayed_tile = desired_display
      _sync_displayed()
  else:
    if desired_display != displayed_tile:
      displayed_tile = desired_display
      _sync_displayed()
    
    if not desired_display:
      displayed_tile = null
      _sync_displayed()
