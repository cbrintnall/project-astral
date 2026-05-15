extends StaticBody3D
class_name Tile

const DIRECTION_EXECUTION_ORDER = [
  Vector2i.UP,
  Vector2i.RIGHT,
  Vector2i.DOWN,
  Vector2i.LEFT,
]

enum TileBind {
  LIFETIME = 0,
  POSITION = 1
}

enum Faction {
  NEUTRAL = 0,
  PLAYER = 1,
  ENEMY = 2,
  ALL = 4
}

@export var def: TileDef
@export var stretcher: Stretcher3D
@export var place_sound := preload("res://audio/place-tile.ogg")

@onready var rotation_axis := Vector3(randf(), randf(), randf()).normalized()

var default_state := "selecting"
var stat := StatStore.new()
var placed := false
var constellation: ConstellationDef
var health: int = 0
var defense := 0
var faction := Faction.NEUTRAL

var _state := CallableStateMachine.new()
var _mouse_entered := false
var _selection: Selection
var _ctx: ExecutionContext
var _remaining_effects := []
var _meshes := []
var _face_mesh: MeshInstance3D
var _face_material = preload("res://materials/extracted/Material_TileFace.material")
var _effects := []
var _constellation_satisfied := false
var _preview_command: BasicCommand
var _preview_highlighter := GridHighlights.new()
var _bind_commands := {}

var _original_hand_marker: Marker3D

func get_effect_context() -> EffectContext:
  return _get_effect_ctx()

func do_chip_damage(amt: int):
  if defense:
    defense -= amt
  else:
    health -= amt
    stretcher.punch(5.0, 10.0)
    Springer.data[stretcher]["rotation"]["velocity"] = Utils.random_unit_sphere() * 25.0
    AudioManager3d.play({
      "stream": preload("res://audio/crack-tile.ogg"),
      "pitch_variance": 0.1,
      "parent": self
    })
    if health <= 0:
      destroy()

func show_target_point_preview(ctx: EffectContext = null) -> bool:
  if not ctx:
    ctx = EffectContext.new()
    ctx.tile = self
  return get_effects().any(func(effect: TileEffect): return effect.would_give_points(ctx)) and not def.initiates

## NOTE: this will NOT call execute, just undo when the bind fires
func register_bind_command(cmd: TileBind, command: Command):
  _bind_commands.get_or_add(cmd, Set.new()).add(command)

func notify_moved(src: Vector3i, dest: Vector3i):
  _drain_bind(TileBind.POSITION)
  
  for effect: TileEffect in get_effects():
    if effect.event == TileEffect.Event.ON_MOVE:
      GameManager.inst.player_tasks.run(effect.run.bind(_get_effect_ctx(), GameManager.inst.active_execution))

func notify_failed_move(target: Vector3i, attempt_data: Dictionary):
  print("%s failed to move, blocking" % def.name)
  var partial = GridManager.inst.has_tile(target)
  var dist := 0.1 if partial else 0.75
  var collision_ctx := TileCollisionContext.new()
  
  var other_tiles = attempt_data[target].to_array()
  other_tiles.erase(self)

  collision_ctx.initiator = self
  collision_ctx.other_tiles = other_tiles
  collision_ctx.source_tile = target
  
  var t = create_tween()
  
  t.tween_property(
    self,
    "global_position",
    global_position.lerp(Vector3(target), dist),
    0.2
  ).set_trans(Tween.TRANS_BACK)
  
  t.tween_callback(
    func():
      stretcher.punch(5.0, 10.0)
      Springer.data[stretcher]["rotation"]["velocity"] = Utils.random_unit_sphere() * 25.0
      AudioManager3d.play({
        "stream": preload("res://audio/crack-tile.ogg"),
        "pitch_variance": 0.1,
        "parent": self
      })
  )
  
  t.tween_property(
    self,
    "global_position",
    get_grid_origin_position(),
    0.1
  ).set_trans(Tween.TRANS_CUBIC)
  
  t.tween_callback(
    func():
      var executor := TileExecutor.new()
      executor.register_group(get_effect_context(), get_effects())
      if partial:
        var tile: Tile = GridManager.inst.get_tile_at(target)
        executor.register_group(tile.get_effect_context(), tile.get_effects())
      executor.event = TileEffect.Event.ON_COLLIDE_TILE
      executor.give_execution_collision_data(collision_ctx)
      add_child(executor)
      GameManager.inst.player_tasks.run(
        func():
          executor.start()
          await executor.finished
      )
  )

func get_grid_origin_position() -> Vector3:
  return Vector3(GridManager.inst.get_tile_loc(self))

func has_effect(effect: TileEffect):
  return _effects.has(effect)

func transform_to(tile_def: TileDef):
  def = tile_def
  
  %EnemyIndicator.visible = def.is_enemy
  _effects = []
  
  for effect: TileEffect in def.effects:
    _effects.push_back(effect)
  
  if def.texture:
    _face_material.albedo_texture = def.texture

  constellation = def.constellation

func set_display_mode():
  _state.current = "display"
  for m in _meshes:
    m.layers = 1
  Springer.register("rotation", stretcher, Vector3.ZERO, Vector3.ZERO, 200.0, 20.0)

func destroy():
  if _state.current == "destroying": return
  
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
  
  var executor := TileExecutor.new()
  executor.register_group(get_effect_context(), get_effects())
  executor.event = TileEffect.Event.ON_DESTROY
  add_child(executor)
  GameManager.inst.player_tasks.run(
    func():
      executor.start()
      await executor.finished
      _drain_bind(TileBind.LIFETIME)
      queue_free()
  )

  _state.current = "destroying"

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
  if _preview_command:
    _preview_command.undo()
  
  if GridManager.inst.hand_selected_tile == self:
    GridManager.inst.hand_selected_tile = null
  
  if _state.current == "placing":
    _state.current = "selecting"
    AudioManager3d.play({ "stream": preload("res://audio/Light Drone Sound (button hover) 9.wav"), "pitch_additional": -0.1 })
    if _selection:
      _selection.cancel()
      _selection = null
     
func set_placed_at(_tile: Vector3i):
  var prev_state = _state.current
  _state.current = "placed"
  for m in _meshes:
    m.layers = 1
  rotation = Vector3.ZERO
  scale = Vector3.ONE
  placed = true
  
  AudioManager3d.play({
    "stream": place_sound,
    "pitch_variance": 0.1,
    "parent": self,
    "volume": 0.5
  })

  if prev_state != "placed":
    var place_executor := TileExecutor.new()
    add_child(place_executor)
    place_executor.register_group(get_effect_context(), get_effects())
    place_executor.event = TileEffect.Event.ON_PLACE
    
    GameManager.inst.player_tasks.run(
      func():
        place_executor.start()
        await place_executor.finished
    )
      
func register_effect(effect: TileEffect):
  _effects.push_back(effect)

func no_neighbors() -> bool:
  return len(get_open_neighbors()) == len(get_valid_neighbor_tiles())

func get_valid_neighbor_tiles() -> Array:
  var my_tile = GridManager.inst.get_tile_loc(self)
  return Constants.ALL_DIRECTIONS \
    .filter(func(dir: Vector3i): return GridManager.inst.is_in_bounds(dir+my_tile)) \
    .map(func(dir: Vector3i): return dir+my_tile)

func get_open_neighbors() -> Array:
  return get_valid_neighbor_tiles() \
    .filter(func(pos: Vector3i): return not GridManager.inst.has_tile(pos))

func get_open_neighbor() -> Vector3i:
  var open := get_open_neighbors()
  
  if open:
    return open.pick_random()
  
  return Vector3i.MIN

func get_neighbors() -> Array:
  var tiles := get_valid_neighbor_tiles()
  return tiles.map(func(pos: Vector3i): return GridManager.inst.get_tile_at(pos)).filter(func(tile: Tile): return tile != null)

func do_execute_fx(ctx: ExecutionContext):
  AudioManager3d.play({
    "stream": preload("res://audio/Light Drone Sound (button hover) 40.wav"),
    "pitch_additional": ctx.tile_execution_count*0.01,
    "parent": self
  })
  
  stretcher.punch(2.0, 5.0)

func get_tile_name() -> String:
  return def.name

func _notification(what: int) -> void:
  if what == NOTIFICATION_PREDELETE and not GameManager.game_closing and not _state.current == "display":
    if _state.current != "destroying":
      push_warning("tried to free %s, but not via destroy, use destroy() instead!" % get_path())

func _ready() -> void:
  health = stat.get_value(preload("res://data/stats/stat_starter_health.tres"))
  _meshes = NodeUtils.get_nodes_with_predicate(self, func(node): return node is MeshInstance3D)
  _face_mesh = NodeUtils.find_child_with_predicate(
    self, 
    func(node): return node is MeshInstance3D and node.mesh.get_surface_count() > 1 and node.mesh.surface_get_material(1) == preload("res://materials/extracted/Material_TileFace.material")
  )
  
  if _face_mesh:
    _face_material = preload("res://materials/extracted/Material_TileFace.material").duplicate()
    _face_mesh.set_surface_override_material(1, _face_material)
    
  _preview_highlighter.mesh = load("res://assets/extracted_mesh/vfxConstellationBox.tres")
  
  add_child(_state)
  GridManager.inst.add_child(_preview_highlighter)
  add_child(stat)
  add_to_group("tile")
  
  _state.register("initializing", CallableStateMachine.noop)
  _state.register("selecting", _selecting)
  _state.register("placing", _placing)
  _state.register("placed", CallableStateMachine.noop)
  _state.register("display", CallableStateMachine.noop)
  _state.register("destroying", CallableStateMachine.noop)
  
  _state.state_changed.connect(_on_state_changed)
  _state.current = default_state
  
  stat.changed.connect(_on_stat_changed)
  
  GridManager.inst.board_changed.connect(_on_board_changed)
  
  _load_def()
  
func _load_def():
  if not def: return

  for effect: TileEffect in def.effects:
    _effects.push_back(effect)

  if def.texture:
    _face_material.albedo_texture = def.texture
    
  if def.is_enemy:
    add_child(load("res://scenes/fx/enemy_indicator_fx.tscn").instantiate())

  constellation = def.constellation
  (%Constellations as MultiMeshInstance3D).multimesh = (%Constellations as MultiMeshInstance3D).multimesh.duplicate()
  
func _drain_bind(bind: TileBind):
  var remaining: Array = _bind_commands.get(bind, Set.new()).to_array()
  _bind_commands[bind] = Set.new()
  while remaining:
    remaining.pop_front().undo()
  
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
    "selecting":
      input_ray_pickable = true
      for m in _meshes:
        m.layers = 2
      if _original_hand_marker:
        reparent(_original_hand_marker)
    "placed":
      input_ray_pickable = false
      for m in _meshes:
        m.layers = 1
      Springer.register("rotation", stretcher, Vector3.ZERO, Vector3.ZERO, 200.0, 20.0)
    "placing":
      _original_hand_marker = get_parent()
      assert(get_parent() is Marker3D)
      input_ray_pickable = false
      for m in _meshes:
        m.layers = 1
      reparent(GridManager.inst)

func _on_stat_changed(changed: StatDef):
  match changed:
    Constants.wrath:
      if stat.get_value(Constants.wrath) > 0.0:
        var has_debuff = get_effects().any(func(effect: TileEffect): return effect == preload("res://data/effects/effect_destroy_from_wrath.tres"))
        if not has_debuff:
          register_effect(preload("res://data/effects/effect_destroy_from_wrath.tres"))
    Constants.chip:
      if stat.get_value(Constants.chip) >= stat.get_value(Constants.defense):
        health -= 1
        stretcher.punch(5.0, 10.0)
        Springer.data[stretcher]["rotation"]["velocity"] = Utils.random_unit_sphere() * 25.0
        AudioManager3d.play({
          "stream": preload("res://audio/crack-tile.ogg"),
          "pitch_variance": 0.1,
          "parent": self
        })

      if health <= 0:
        destroy()

func _get_effect_ctx() -> EffectContext:
  var ctx := EffectContext.new()
  
  ctx.tile = self
  
  return ctx

func _selecting(machine: CallableStateMachine, delta: float):
  if _mouse_entered:
    var curr_scale := stretcher.global_basis.get_scale()
    var direction = -get_viewport().get_camera_3d().global_basis.z
    var target := Basis.looking_at(direction, get_viewport().get_camera_3d().global_basis.y)
    target *= Basis.from_euler(Vector3(PI*0.5, 0.0, 0.0))
    stretcher.global_basis = stretcher.global_basis.orthonormalized().slerp(target, 0.1).scaled(curr_scale)
  else:
    stretcher.rotate(rotation_axis, delta)
  position = position.lerp(Vector3.ZERO, delta*10.0)
  _preview_highlighter.visible = false

func _placing(machine: CallableStateMachine, delta: float):
  var curr_scale := stretcher.global_basis.get_scale()
  # NOTE: identity basis points straight up, no need for another direction
  var target := Basis()
  stretcher.global_basis = stretcher.global_basis.orthonormalized().slerp(target, 0.1).scaled(curr_scale)
  global_position = global_position.lerp(GridManager.inst.grid_position_3d+Vector3i.UP, 0.3)
  
  var state = Selection.State.DEFAULT
  
  if not GridManager.inst.could_place_tile(GridManager.inst.grid_position_3d):
    state = Selection.State.ERROR
    
  _selection.state = state
  _preview_highlighter.visible = true

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
          global_position = Vector3.UP*100.0
          AudioManager3d.play({ "stream": preload("res://audio/Light Drone Sound (button hover) 9.wav") })
          _selection = selection
      )
      selection.on_process = _selection_process_update_area_previews
      selection.canceled.connect(unselect)
      selection.on_choose = _try_place_self.bind(selection)

      if GridManager.inst.try_start_selection(selection):
        if _preview_command:
          _preview_command.undo()
        GridManager.inst.hand_selected_tile = self
        var preview := TileDataPreviewer.TilePreviewData.new()
        preview.effects = get_effects()
        preview.context = EffectContext.new()
        preview.name = def.name
        preview.priority = 2
        _preview_command = UI.inst.tile_previewer.push_preview(preview)
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
      
func _selection_process_update_area_previews(_delta: float):
  _preview_highlighter.spots = []

  var spots = []
  var ctx := EffectContext.from_override(GridManager.inst.grid_position_3d)
  for effect: TileEffect in get_effects():
    if effect.main_target:
      spots.append_array(effect.main_target.get_target(ctx))

  _preview_highlighter.spots = spots
      
func _try_place_self(selection: Selection):
  if GridManager.inst.try_place_tile(self, GridManager.inst.grid_position_3d):
    HandManager.inst.discard.push_back(def)
    BoardCamera.inst.shake(0.2, 0.01)
    selection.cancel()
    
    # NOTE: not a fan of having the tile clean up its parent, but for now it'll do
    assert(_original_hand_marker != null)
    _original_hand_marker.queue_free()
    _preview_highlighter.queue_free()

func _unhandled_input(event: InputEvent) -> void:
  if not _mouse_entered: return
  
  if event is InputEventMouseButton:
    if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
      _on_select()

#func _process(delta: float) -> void:
  #%Constellations.visible = constellation != null
  #if constellation:
    #%Constellations.global_position = Vector3.ZERO
    #var targets = constellation.tile_targets.get_target(_get_effect_ctx())
    #(%Constellations as MultiMeshInstance3D).multimesh.instance_count = len(targets)
    #var count := 0
    #for tile in targets:
      #var t := Transform3D().translated(Vector3(tile))
      #(%Constellations as MultiMeshInstance3D).multimesh.set_instance_transform(count, t)
      #count += 1
