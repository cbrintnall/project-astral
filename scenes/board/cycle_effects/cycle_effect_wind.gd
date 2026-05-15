extends TileEffect
class_name CycleEffectWind

var direction := Vector3i.FORWARD

var _all_tile_target: TileTargetDef = load("res://data/targets/tile_target_all_tiles.tres")
  
func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "NEEDS DESCRIPTION"
  
func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  var opts = [-1, 0, 1]
  opts.shuffle()
  direction = Vector3i(opts.pop_front(), 0, opts.pop_front())
  
  var handler := ResolutionHandler.new()
  handler.context.start_execution()
  GameManager.inst.add_child(handler)
  for tile: Vector3i in _all_tile_target.get_target(EffectContext.new(), true):
    var curr: Tile = GridManager.inst.get_tile_at(tile)
    var res: ResolutionCommand = GridManager.inst.submit_move_attempt(curr, tile+direction, handler.context)
    handler.context.register_resolution(res)
  handler.start()
