extends CanvasLayer
class_name UI

static var inst: UI

@onready var score_label: Label = %ScoreLabel
@onready var turn_label: Label = %TurnLabel
@onready var cycle_label: Label = %CycleLabel
@onready var help: Control = $Help
@onready var system_label: RichTextLabel = %SystemMessage
@onready var tile_display: MarginContainer = %TileDisplay
@onready var tile_previewer: TileDataPreviewer = %TileData
@onready var choose_tiles: ChooseTilesUI = $ChooseTiles

var _tile_display_offset := 0.0
var _tile_display_open := false
var _tile_displays := {}

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
  
  _tile_display_offset = tile_display.size.y
  system_label.self_modulate = Color.TRANSPARENT

  %TryAgainRoot.modulate.a = 0.0
  %ToggleTileDisplay.pressed.connect(func(): _tile_display_open = not _tile_display_open)
  
  %Bluesky.pressed.connect(
    func():
      OS.shell_open("https://bsky.app/profile/otterbee.bsky.social")
  )
  
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
  
  %RetryButton.pressed.connect(
    func():
      get_tree().change_scene_to_file("res://game.tscn")
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

func _process(delta: float) -> void:
  score_label.text = "%d/%d" % [ GameManager.inst.current_score, GameManager.inst.required_score ]
  turn_label.text = "Turn: %d/%d" % [ GameManager.inst.turn, Constants.TURNS_PER_SCORE ]
  cycle_label.text = "Cycle: %d" % [ GameManager.inst.cycle ]
  %MoneyLabel.text = "Money: %d" % [ GameManager.inst.money ]
  %PlayButton.disabled = GameManager.inst.active_execution and GameManager.inst.active_execution.active_round
  
  %MultData.visible = false
  %OverrideData.visible = false

  var hovered := GridManager.inst.grid_position_3d
  var ctx: GridContext = GridManager.inst.get_mods_at_point(GridManager.inst.grid_position_3d)

  if ctx.has_mult():
    %MultLabel.text = "%+00.0f%%" % [ ctx.points_multipliers*100.0 ]
    %MultData.visible = true
    var target_position = GridManager.inst.get_viewport().get_camera_3d().unproject_position(Vector3(hovered))
    target_position -= %MultData.get_combined_pivot_offset()
    target_position += Vector2.UP*50.0
    %MultData.global_position = %MultData.global_position.lerp(target_position, 0.1)
    %MultData.reset_size()
    
  if ctx.has_information():
    if ctx.point_source_override.target:
      %OverrideAmount.text = "%d/%d" % [ctx.point_source_override.current, ctx.point_source_override.target]
    else:
      %OverrideAmount.text = "%d" % [ctx.point_source_override.current]
    %OverrideData.visible = true
    var target_position = GridManager.inst.get_viewport().get_camera_3d().unproject_position(ctx.point_source_override.target_point+(Vector3.UP))
    target_position -= %OverrideData.get_combined_pivot_offset()
    %OverrideData.global_position = %OverrideData.global_position.lerp(target_position, 0.3)
    %OverrideData.reset_size()
  
  for i in len(HandManager.inst.hand):
    if not _tile_displays.has(i):
      var next = load("res://scenes/ui/tile_preview.tscn").instantiate()
      next.tile = HandManager.inst.hand[i]
      %TilePreviewRoot.add_child(next)
      _tile_displays[i]=next
  
  if _tile_display_open:
    tile_display.anchor_top = lerp(tile_display.anchor_top, 0.2, 0.1)
  else:
    tile_display.anchor_top = lerp(tile_display.anchor_top, 1.0, 0.1)
  
  var play_text := "Play"
  
  match GameManager.inst.current_state:
    "shop":
      play_text = "Leave"
    "wait_for_accept_shop":
      play_text = "Next"
    "end_game":
      %UpperBar.modulate.a = lerp(%UpperBar.modulate.a, 0.0, delta*5.0)
      if not GameManager.inst.won:
        %TryAgainRoot.visible = true
        %TryAgainRoot.modulate.a = lerp(%TryAgainRoot.modulate.a, 1.0, delta*5.0)
      
  %PlayText.text = play_text
