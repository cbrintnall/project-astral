extends StaticBody3D
class_name Tile

const DIRECTION_EXECUTION_ORDER = [
  Vector2i.UP,
  Vector2i.RIGHT,
  Vector2i.DOWN,
  Vector2i.LEFT,
]

@export var def: TileDef

@onready var stretcher: Stretcher3D = $Stretcher3D
@onready var rotation_axis := Vector3(randf(), randf(), randf()).normalized()

var stat := StatStore.new()
var placed := false
var constellation: ConstellationDef

var _state := CallableStateMachine.new()
var _mouse_entered := false
var _selection: Selection
var _ctx: ExecutionContext
var _timer := BetterTimer.new(0.5)
var _remaining_effects := []
var _current_effect_task: Task
var _meshes := []
var _face_mesh: MeshInstance3D
var _face_material = preload("res://materials/extracted/Material_TileFace.material")
var _effects := []
var _constellation_satisfied := false

func set_display_mode():
  _state.current = "display"
  for m in _meshes:
    m.layers = 1
  Springer.register("rotation", stretcher, Vector3.ZERO, Vector3.ZERO, 200.0, 20.0)

func destroy():
  AudioManager3d.play({
    "stream": preload("res://audio/break-tile.ogg"),
    "pitch_variance": 0.05,
    "parent": self
  })
  
  var p = NodeUtils.fire_particles_at(
    get_tree().current_scene,
    load("res://scenes/fx/smoke_stack_particles.tscn").instantiate()
  )
  
  p.global_position = global_position
  
  queue_free()

func select():
  _on_select()

func get_effects() -> Array:
  return _effects

func has_pre_round_effects() -> bool:
  return get_effects().any(func(effect: TileEffect): return effect.event == TileEffect.Event.ON_ROUND_START)

func has_post_round_effects() -> bool:
  return get_effects().any(func(effect: TileEffect): return effect.event == TileEffect.Event.ON_ROUND_END)

## NOTE: do we want tiles to define directions? or should they just always be all four?
func get_directions() -> Array:
  #return DIRECTION_EXECUTION_ORDER.filter(func(dir: Vector2i): return def.execute_directions.has(dir))
  return DIRECTION_EXECUTION_ORDER

func is_executing() -> bool:
  return _state.current == "execute" or _state.current == "no_execute"

func execute(ctx: ExecutionContext, event: TileEffect.Event):
  AudioManager3d.play({
    "stream": preload("res://audio/Light Drone Sound (button hover) 40.wav"),
    "pitch_additional": ctx.tile_execution_count*0.01,
    "parent": self
  })
  
  stretcher.punch(2.0, 5.0)
  
  _state.current = "execute"
  _ctx = ctx
  _ctx.current_tile = self
  
  for effect: TileEffect in get_effects():
    if effect.event == event:
      _remaining_effects.push_back(effect)

func unselect():
  if GridManager.inst.hand_selected_tile == self:
    GridManager.inst.hand_selected_tile = null
  
  if _state.current == "placing":
    _state.current = "selecting"
    AudioManager3d.play({ "stream": preload("res://audio/Light Drone Sound (button hover) 9.wav"), "pitch_additional": -0.1 })
    if _selection:
      _selection.cancel()
      _selection = null
      
func set_placed_at(_tile: Vector3i):
  _state.current = "placed"
  for m in _meshes:
    m.layers = 1
  rotation = Vector3.ZERO
  scale = Vector3.ONE
  placed = true
  
  AudioManager3d.play({
    "stream": preload("res://audio/place-tile.ogg"),
    "pitch_variance": 0.1,
    "parent": self,
    "volume": 0.5
  })
  
  for effect: TileEffect in get_effects():
    if effect.event == TileEffect.Event.ON_PLACE:
      GameManager.inst.player_tasks.run(effect.run.bind(_get_effect_ctx(), GameManager.inst.active_execution))
      
func register_effect(effect: TileEffect):
  _effects.push_back(effect)

func get_open_neighbor() -> Vector3i:
  var my_tile = GridManager.inst.get_tile_loc(self)
  for dir in Constants.ALL_DIRECTIONS:
    if not GridManager.inst.has_tile(dir+my_tile):
      return dir+my_tile
  return Vector3i.MIN

func _ready() -> void:
  add_child(_state)
  add_to_group("tile")
  
  (%Constellations as MultiMeshInstance3D).multimesh = (%Constellations as MultiMeshInstance3D).multimesh.duplicate()
  
  _state.register("selecting", _selecting)
  _state.register("placing", _placing)
  _state.register("placed", _placed)
  _state.register("execute", _executing)
  _state.register("no_execute", _no_execute)
  _state.register("deferred", _deferred)
  _state.register("waiting_for_end", _waiting_for_end)
  _state.register("display", _display)
  
  _state.state_changed.connect(_on_state_changed)
  
  add_child(stat)
  
  stat.changed.connect(_on_stat_changed)
  
  GridManager.inst.board_changed.connect(_on_board_changed)
  
  _meshes = NodeUtils.get_nodes_with_predicate(self, func(node): return node is MeshInstance3D)
  _face_mesh = NodeUtils.find_child_with_predicate(
    self, 
    func(node): return node is MeshInstance3D and node.mesh.surface_get_material(1) == preload("res://materials/extracted/Material_TileFace.material")
  )
  
  _face_material = preload("res://materials/extracted/Material_TileFace.material").duplicate()
  if _face_mesh:
    _face_mesh.set_surface_override_material(1, _face_material)
  
  for effect: TileEffect in def.effects:
    _effects.push_back(effect)
  
  if def.texture:
    _face_material.albedo_texture = def.texture
  
  for m in _meshes:
    m.layers = 2
    
  constellation = def.constellation
  
func _on_board_changed():
  var before = _constellation_satisfied
  _constellation_satisfied = constellation != null and constellation.tile_targets.get_target(_get_effect_ctx()).all(
    func(tile: Vector3i):
      return GridManager.inst.has_tile(tile)
  )
  
  if before and not _constellation_satisfied:
    (%Constellations as MultiMeshInstance3D).set_instance_shader_parameter("glow", 10.0)
    AudioManager3d.play({
      "stream": preload("res://audio/constellation-broken.ogg")
    })
  if not before and _constellation_satisfied:
    (%Constellations as MultiMeshInstance3D).set_instance_shader_parameter("glow", 100.0)
    AudioManager3d.play({
      "stream": preload("res://audio/constellation-complete.ogg")
    })
func _on_state_changed(state: String):
  match state:
    "placing":
      for m in _meshes:
        m.layers = 2
    "selecting":
      input_ray_pickable = true
      for m in _meshes:
        m.layers = 2
    "placed":
      input_ray_pickable = false
      for m in _meshes:
        m.layers = 1
    "placing":
      input_ray_pickable = false

func _on_stat_changed(changed: StatDef):
  match changed:
    Constants.wrath:
      if stat.get_value(Constants.wrath) > 0.0:
        var has_debuff = get_effects().any(func(effect: TileEffect): return effect == preload("res://data/effects/effect_destroy_from_wrath.tres"))
        if not has_debuff:
          register_effect(preload("res://data/effects/effect_destroy_from_wrath.tres"))

func _get_effect_ctx() -> EffectContext:
  var ctx := EffectContext.new()
  
  ctx.tile = self
  
  return ctx

func _display(machine: CallableStateMachine, delta: float):
  pass

func _deferred(machine: CallableStateMachine, delta: float):
  pass

func _executing(machine: CallableStateMachine, delta: float):
  stretcher.position = stretcher.position.lerp(Vector3.UP, 0.1)
  
  if not _current_effect_task:
    if _remaining_effects:
      _current_effect_task = Task.wait_for(_remaining_effects.pop_front().run.bind(_get_effect_ctx(), _ctx))
    else:
      _state.current = "waiting_for_end"
      _ctx = null
      stretcher.punch(1.0, 3.0)
      
  elif _current_effect_task.finished:
    _current_effect_task = null

func _no_execute(machine: CallableStateMachine, delta: float):
  stretcher.position = stretcher.position.lerp(Vector3.UP, 0.1)
  
  if _timer.check(delta):
    _state.current = "waiting_for_end"
    _ctx = null
    stretcher.punch(1.0, 3.0)

func _selecting(machine: CallableStateMachine, delta: float):
  stretcher.rotate(rotation_axis, delta)
  position = position.lerp(Vector3.ZERO, delta*10.0)

func _placing(machine: CallableStateMachine, delta: float):
  stretcher.rotate(rotation_axis, delta*0.25)
  position = position.lerp(Vector3.UP, delta*10.0)
  
  var state = Selection.State.DEFAULT
  
  if GridManager.inst.has_tile(GridManager.inst.grid_position_3d):
    state = Selection.State.ERROR
    
  var has_neighbor = DIRECTION_EXECUTION_ORDER.any(
    func(dir): 
      return GridManager.inst.has_tile(GridManager.inst.grid_position_3d+Vector3i(dir.x, 0, dir.y))
  ) 
  if not has_neighbor:
    state = Selection.State.WARNING
    
  _selection.state = state

func _placed(machine: CallableStateMachine, delta: float):
  stretcher.rotation = Vector3.ZERO

func _waiting_for_end(machine: CallableStateMachine, delta: float):
  stretcher.position = stretcher.position.lerp(Vector3.ZERO, 0.05)

func _mouse_enter() -> void:
  GridManager.inst.hand_hovered_tile = self
  _mouse_entered = true
  stretcher.punch(1.0, 3.0)
  AudioManager3d.play({
    "stream": preload("res://audio/hover-stone.ogg"),
    "pitch_variance": 0.1
  })
  
func _mouse_exit() -> void:
  if GridManager.inst.hand_hovered_tile == self:
    GridManager.inst.hand_hovered_tile = null
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

      if GridManager.inst.try_start_selection(selection):
        GridManager.inst.hand_selected_tile = self
    "placing":
      unselect()
    "placed":
      print("hello?")
    "display":
      stretcher.punch(5.0,10.0)
      Springer.data[stretcher]["rotation"]["velocity"] = Vector3(500.0, 0.0, 0.0)
      if GameManager.inst.money >= def.shop_cost:
        GameManager.inst.money -= def.shop_cost
        BoardCamera.inst.shake(0.1, 0.1)
        HandManager.inst.add_tile(def)
        queue_free()
      
func _try_place_self(selection: Selection):
  if GridManager.inst.try_place_tile(self, GridManager.inst.grid_position_3d):
    BoardCamera.inst.shake(0.2, 0.01)
    selection.cancel()

func _unhandled_input(event: InputEvent) -> void:
  if not _mouse_entered: return
  
  if event is InputEventMouseButton:
    if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
      _on_select()

func _process(delta: float) -> void:
  %Constellations.visible = constellation != null
  if constellation:
    %Constellations.global_position = Vector3.ZERO
    var targets = constellation.tile_targets.get_target(_get_effect_ctx())
    (%Constellations as MultiMeshInstance3D).multimesh.instance_count = len(targets)
    var count := 0
    for tile in targets:
      var t := Transform3D().translated(Vector3(tile))
      (%Constellations as MultiMeshInstance3D).multimesh.set_instance_transform(count, t)
      count += 1
