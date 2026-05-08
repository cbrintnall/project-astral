extends CanvasLayer
class_name UI

static var inst: UI

func _ready() -> void:
  inst = self

  %PlayButton.pressed.connect(GameManager.inst.try_execute_turn)
