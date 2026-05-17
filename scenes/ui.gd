extends CanvasLayer
class_name UI

static var inst: UI

@onready var score_label: Label = %ScoreLabel
@onready var turn_label: Label = %TurnLabel
@onready var cycle_label: Label = %CycleLabel
@onready var help: Control = $Help
@onready var system_label: RichTextLabel = %SystemMessage
@onready var draw_pile_display: MarginContainer = %HandTileDisplay
@onready var discard_pile_display: = %DiscardTileDisplay
@onready var tile_previewer: TileDataPreviewer = %TileData
@onready var choose_tiles: ChooseTilesUI = $ChooseTiles

var _fx := {}

func show_tooltip(tooltip: String) -> Command:
  var cmd := BasicCommand.from(
    func(): 
      %Tooltip.visible = true
      %TooltipText.text = tooltip
      %Tooltip.reset_size()
      ,
    func(): 
      %Tooltip.visible = false
      %TooltipText.text = ""
  )
  
  cmd.execute()
  
  return cmd

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

  %Tooltip.visible = false
  system_label.self_modulate = Color.TRANSPARENT

  %TryAgainRoot.modulate.a = 0.0
  
  %ToggleMusic.pressed.connect(
    func():
      var music_idx = AudioServer.get_bus_index("Music")
      var current = AudioServer.get_bus_volume_linear(music_idx)
      var next = 1.0 if current < 1.0 else 0.0
      
      AudioServer.set_bus_volume_linear(music_idx, next)
  )
  
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
          GameManager.inst.enter_shop("deal")
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
  
  GameManager.inst.point_source.received.connect(
    func():
      score_label.offset_transform_position = Utils.random_unit_circle()*5.0
      score_label.offset_transform_scale = Vector2(randf_range(1.0, 1.2), randf_range(1.0, 1.2))
  )
  
func _unhandled_input(event: InputEvent) -> void:
  if event.is_action_pressed("ui_cancel"):
    help.visible = false

func _process_in_world_uis(delta: float):
  var hovered := GridManager.inst.grid_position_3d
  var ctx: GridContext = GridManager.inst.get_mods_at_point(GridManager.inst.grid_position_3d)
  var tile: Tile = GridManager.inst.get_tile_at(hovered)
  
  if tile and tile.def.initiates:
    return
    
  var tile_hovered_uis = []
  if ctx.has_information():
    if ctx.point_source_override.target:
      %OverrideAmount.text = "%d/%d" % [ctx.point_source_override.current, ctx.point_source_override.target]
    else:
      %OverrideAmount.text = "%d" % [ctx.point_source_override.current]
    %OverrideData.visible = true
    %OverrideData.reset_size()
    var target_position = GridManager.inst.get_viewport().get_camera_3d().unproject_position(ctx.point_source_override.target_point+(Vector3.UP))
    if GridManager.inst.ui_hover_point.is_visible_in_tree():
      target_position = GridManager.inst.get_viewport().get_camera_3d().unproject_position(GridManager.inst.ui_hover_point.global_position)
    %OverrideData.global_position = %OverrideData.global_position.lerp(target_position, 0.3)
    tile_hovered_uis.push_back(%OverrideData)

  if ctx.has_mult():
    %MultLabel.text = "%+00.0f%%" % [ ctx.points_multipliers*100.0 ]
    %MultData.visible = true
    var target_position = GridManager.inst.get_viewport().get_camera_3d().unproject_position(Vector3(hovered))
    if GridManager.inst.ui_hover_point.is_visible_in_tree():
      target_position = GridManager.inst.get_viewport().get_camera_3d().unproject_position(GridManager.inst.ui_hover_point.global_position)
    %MultData.reset_size()
    
    if tile_hovered_uis:
      var last: Control = tile_hovered_uis.back()
      target_position = last.global_position + (Vector2.UP*(last.size.y+10.0))
      target_position += Vector2.UP*50.0

    %MultData.global_position = %MultData.global_position.lerp(target_position, 0.1)
    tile_hovered_uis.push_back(%MultData)

  if tile:
    %HoveredTileData.visible = true
    %HoveredTileLabelDefense.text = str(tile.defense)
    %HoveredTileLabelHealth.text = "%d/%d" % [ tile.health, roundi(tile.stat.get_value(preload("res://data/stats/stat_starter_health.tres"))) ]
    var target_position = GridManager.inst.get_viewport().get_camera_3d().unproject_position(Vector3(hovered))
    if GridManager.inst.ui_hover_point.is_visible_in_tree():
      target_position = GridManager.inst.get_viewport().get_camera_3d().unproject_position(GridManager.inst.ui_hover_point.global_position)
    %HoveredTileData.reset_size()
    
    if tile_hovered_uis:
      var last: Control = tile_hovered_uis.back()
      target_position = last.global_position + (Vector2.UP*(last.size.y+10.0)) 
    
    %HoveredTileData.global_position = %HoveredTileData.global_position.lerp(target_position, 0.3)
    tile_hovered_uis.push_back(%HoveredTileData)

func _process(delta: float) -> void:
  for effect in GameManager.inst._next_cycle_tasks:
    if not _fx.has(effect):
      var container = load("res://scenes/cycle_effect_container.tscn").instantiate()
      %CycleEffectsRoot.add_child(container)
      _fx[effect]=container
      container.effect = effect
  for effect: TileEffect in _fx.keys():
    if not GameManager.inst._next_cycle_tasks.has(effect):
      _fx[effect].queue_free()
      _fx.erase(effect)
  
  var rect := get_viewport().get_visible_rect()
  %Tooltip.global_position = get_viewport().get_mouse_position()
  %Tooltip.global_position.x = clampf(%Tooltip.global_position.x, 0.0, rect.size.x-%Tooltip.size.x)
  %Tooltip.global_position.y = clampf(%Tooltip.global_position.y, 0.0, rect.size.y-%Tooltip.size.y)
  %Tooltip.reset_size()
  
  %CycleProgress.max_value = GameManager.inst.required_score
  %CycleProgress.value = GameManager.inst.current_score
  score_label.text = "%d/%d" % [ GameManager.inst.current_score, GameManager.inst.required_score ]
  turn_label.text = "Turn: %d/%d" % [ GameManager.inst.turn, Constants.TURNS_PER_SCORE ]
  cycle_label.text = "Cycle: %d/%d" % [ GameManager.inst.cycle, len(Constants.REQUIRED_SCORES) ]
  %MoneyLabel.text = "Money: %d" % [ GameManager.inst.money ]
  %PlayButton.disabled = (GameManager.inst.active_execution and GameManager.inst.active_execution.active_round) or TutorialManager.inst.is_active()
  
  %MultData.visible = false
  %OverrideData.visible = false
  %HoveredTileData.visible = false

  _process_in_world_uis(delta)

  var play_text := "Play"

  var points := PackedVector2Array()
  %CycleEffectLine.global_position = %CycleLabel.global_position
  points.push_back(Vector2.ZERO)
  for i in %CycleEffectsRoot.get_child_count():
    var child = %CycleEffectsRoot.get_child(i)
    points.push_back(%CycleEffectLine.to_local(child.global_position+child.get_combined_pivot_offset()+child.offset_transform_position))
  %CycleEffectLine.points = points
  
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
