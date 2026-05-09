extends Node
class_name GameManager

static var inst: GameManager

@export var camera: Camera3D
@export var selection_svp: SubViewport

var current_score := 0
var required_score := 30

var active_execution: ExecutionContext:
  get:
    return _current_context

var _state := CallableStateMachine.new()
var _deal_timer := BetterTimer.new(0.1)

var _initiate_tiles := []
var _current_context: ExecutionContext
var _execution_order := []

func try_execute_turn():
  _state.current = "begin_execution"

func _ready() -> void:
  inst = self
  add_child(_state)
  
  _state.register("deal", _deal)
  _state.register("wait_for_player", _wait_for_player)
  _state.register("begin_execution", _begin_execution)
  _state.register("execute", _execute_turn)
  _state.register("post_round", _post_round)
  
  selection_svp.world_3d = get_viewport().find_world_3d()
  
  await Utils.wait_until(func(): return GridManager.inst != null)
  
  var start_tile = load("res://scenes/board/tile.tscn").instantiate()
  start_tile.def = load("res://data/tiles/tile_source_tile.tres")
  assert(GridManager.inst.try_place_tile(start_tile, Vector3i.ZERO), "This should never fail")
  BoardCamera.inst.try_set_focus(GridManager.inst.map_to_global(Vector3i.ZERO))
  var start_mesh: MeshInstance3D = NodeUtils.find_child_with_predicate(start_tile, func(node): return node is MeshInstance3D)
  start_mesh.material_override = preload("res://materials/material_debug.tres")

  #for x in 5:
    #var current := Vector3i.ZERO
    #for i in randi_range(10, 20):
      #var next = load("res://scenes/board/tile.tscn").instantiate()
      #next.def = load("res://data/tiles/tile_no_effects.tres")
      #var values = [0, 1]
      #values.shuffle()
      #current += Vector3i(values.pop_back(), 0, values.pop_back())
      #GridManager.inst.try_place_tile(next, current)
  
func _deal(machine: CallableStateMachine, delta: float):
  TileHand.inst.distribute_hand()
  _state.current = "wait_for_player"

func _wait_for_player(machine: CallableStateMachine, delta: float):
  pass

func _post_round(machine: CallableStateMachine, delta: float):
  _state.current = "deal"

func _begin_execution(machine: CallableStateMachine, delta: float):
  var tiles = GridManager.inst.get_played_tiles()
  _initiate_tiles = tiles.filter(func(tile: Tile): return tile.def.initiates)
  _current_context = ExecutionContext.new()
  TileHand.inst.discard_hand()
  _execution_order = GridManager.inst.collect_tiles_in_execution_order()
  _state.current = "execute"
  
func _execute_turn(machine: CallableStateMachine, delta: float):
  if _current_context.current_tile:
    var loc = GridManager.inst.get_tile_loc(_current_context.current_tile)
    if loc != Vector3i.MIN:
      BoardCamera.inst.try_set_focus(loc)
  
  if _current_context.current_tile == null:
    if _execution_order:
      _current_context.current_tile = _execution_order.pop_front()
      _current_context.current_tile.execute(_current_context)
    else:
      _state.current = "post_round"
      _current_context = null
