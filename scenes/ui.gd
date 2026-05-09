extends CanvasLayer
class_name UI

static var inst: UI

@onready var score_label: Label = %ScoreLabel

func _ready() -> void:
  inst = self

  %PlayButton.pressed.connect(GameManager.inst.try_execute_turn)

func _process(delta: float) -> void:
  score_label.text = "%d/%d" % [ GameManager.inst.current_score, GameManager.inst.required_score ]
