extends Node
class_name GameManager

static var inst: GameManager

@export var camera: Camera3D

var _state := CallableStateMachine.new()
var _deal_timer := BetterTimer.new(0.1)

func _ready() -> void:
  inst = self
  add_child(_state)
  
  _state.register("deal", _deal)
  
func _deal(machine: CallableStateMachine, delta: float):
  pass
