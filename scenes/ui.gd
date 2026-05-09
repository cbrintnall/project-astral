extends CanvasLayer
class_name UI

static var inst: UI

@onready var score_label: Label = %ScoreLabel
@onready var turn_label: Label = %TurnLabel
@onready var cycle_label: Label = %CycleLabel

var displayed_tile: Tile

func _ready() -> void:
  inst = self

  %PlayButton.pressed.connect(GameManager.inst.try_execute_turn)

func _sync_displayed():
  NodeUtils.clear_children(%EffectsDisplayRoot)
  
  if displayed_tile:
    %TileTitle.text = displayed_tile.def.name
    var ctx := EffectContext.new()
    ctx.tile = displayed_tile
    for effect in displayed_tile.get_effects():
      var display: EffectsDisplayRoot = load("res://scenes/ui/tile_effect_display.tscn").instantiate()
      %EffectsDisplayRoot.add_child(display)
      display.effect_ctx = ctx
      display.effect = effect

func _process(_delta: float) -> void:
  score_label.text = "%d/%d" % [ GameManager.inst.current_score, GameManager.inst.required_score ]
  turn_label.text = "Turn: %d/%d" % [ GameManager.inst.turn, Constants.TURNS_PER_SCORE ]
  cycle_label.text = "Cycle: %d" % [ GameManager.inst.cycle ]
  
  %TileData.visible = displayed_tile != null

  var desired_display: Tile = null
  
  if GridManager.inst.hand_hovered_tile:
    desired_display = GridManager.inst.hand_hovered_tile
  elif GridManager.inst.grid_hovered_tile:
    desired_display = GridManager.inst.grid_hovered_tile
  elif GridManager.inst.hand_selected_tile:
    desired_display = GridManager.inst.hand_selected_tile

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
