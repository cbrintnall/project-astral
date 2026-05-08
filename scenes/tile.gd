extends StaticBody3D
class_name Tile

const DIRECTION_EXECUTION_ORDER = [
  Vector2i.UP,
  Vector2i.RIGHT,
  Vector2i.DOWN,
  Vector2i.LEFT,
]

@export var def: TileDef

@onready var mesh: MeshInstance3D = $Stretcher3D/MeshInstance3D
@onready var stretcher: Stretcher3D = $Stretcher3D

@onready var rotation_axis := Vector3(randf(), randf(), randf()).normalized()

var _state := CallableStateMachine.new()
var _mouse_entered := false
var _selection: Selection
var _ctx: ExecutionContext
var _remaining_execution_directions := []
var _timer := BetterTimer.new(0.5)

func get_directions() -> Array:
  return DIRECTION_EXECUTION_ORDER.filter(func(dir: Vector2i): return def.execute_directions.has(dir))

func is_executing() -> bool:
  return _state.current == "execute"
  
func resume_execution():
  assert(_state.current == "deferred")
  _state.current = "execute"

func execute(ctx: ExecutionContext):
  _state.current = "execute"
  _ctx = ctx
  _ctx.current_tile = self
  _ctx.current_execution_chain.push_back(self)
  _remaining_execution_directions = DIRECTION_EXECUTION_ORDER.filter(func(dir: Vector2i): return def.execute_directions.has(dir))

func unselect():
  if _state.current == "placing":
    _state.current = "selecting"
    AudioManager3d.play({ "stream": preload("res://audio/Light Drone Sound (button hover) 9.wav"), "pitch_additional": -0.1 })
    if _selection:
      _selection.cancel()
      _selection = null
      
func set_placed_at(_tile: Vector3i):
  _state.current = "placed"
  mesh.layers = 1
  rotation = Vector3.ZERO
  scale = Vector3.ONE

func _ready() -> void:
  add_child(_state)
  add_to_group("tile")
  
  _state.register("selecting", _selecting)
  _state.register("placing", _placing)
  _state.register("placed", _placed)
  _state.register("execute", _executing)
  _state.register("deferred", _deferred)
  _state.register("waiting_for_end", _waiting_for_end)
  
  _state.state_changed.connect(_on_state_changed)
  
func _on_state_changed(state: String):
  match state:
    "selecting":
      input_ray_pickable = true
    "placed":
      input_ray_pickable = false
    "placing":
      input_ray_pickable = false

func _deferred(machine: CallableStateMachine, delta: float):
  pass

func _executing(machine: CallableStateMachine, delta: float):
  # TODO: Add effect code here
  
  if _timer.check(delta):
    _state.current = "waiting_for_end"
    _ctx.current_tile = null
    _ctx = null

func _selecting(machine: CallableStateMachine, delta: float):
  mesh.rotate(rotation_axis, delta)
  position = position.lerp(Vector3.ZERO, delta*10.0)

func _placing(machine: CallableStateMachine, delta: float):
  mesh.rotate(rotation_axis, delta*0.25)
  position = position.lerp(Vector3.UP, delta*10.0)

func _placed(machine: CallableStateMachine, delta: float):
  mesh.rotation = Vector3.ZERO

func _waiting_for_end(machine: CallableStateMachine, delta: float):
  pass

func _mouse_enter() -> void:
  _mouse_entered = true
  stretcher.punch(1.0, 3.0)
  AudioManager3d.play({
    "stream": preload("res://audio/hover-stone.ogg"),
    "pitch_variance": 0.1
  })
  
func _mouse_exit() -> void:
  _mouse_entered = false
  
func _on_select():
  match _state.current:
    "selecting":
      var selection := Selection.new()
      selection.started.connect(
        func():
          stretcher.punch(3.0, 5.0)
          _state.current = "placing"
          AudioManager3d.play({ "stream": preload("res://audio/Light Drone Sound (button hover) 9.wav") })
          _selection = selection
      )
      selection.canceled.connect(unselect)
      selection.on_choose = _try_place_self.bind(selection)

      GridManager.inst.try_start_selection(selection)
    "placing":
      unselect()
    "placed":
      pass
      
func _try_place_self(selection: Selection):
  if GridManager.inst.try_place_tile(self, GridManager.inst.grid_position_3d):
    selection.cancel()

func _unhandled_input(event: InputEvent) -> void:
  if not _mouse_entered: return
  
  if event is InputEventMouseButton:
    if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
      _on_select()
