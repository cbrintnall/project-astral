extends Node
class_name GameManager

static var inst: GameManager

@export var camera: Camera3D
@export var selection_svp: SubViewport

var _state := CallableStateMachine.new()
var _deal_timer := BetterTimer.new(0.1)

func _ready() -> void:
  inst = self
  add_child(_state)
  
  _state.register("deal", _deal)
  
  selection_svp.world_3d = get_viewport().find_world_3d()
  
func _deal(machine: CallableStateMachine, delta: float):
  pass
