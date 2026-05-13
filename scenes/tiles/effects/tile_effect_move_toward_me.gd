extends TileEffect
class_name TileEffectMoveTowardMe

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "Moves all marked tiles in toward this tile"

func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  var my_tile: Vector3i = GridManager.inst.get_tile_loc(effect_ctx.tile)
  for target: Vector3i in main_target.get_target(effect_ctx):
    var tile: Tile = GridManager.inst.get_tile_at(target)
    if tile:
      var next = target+Vector3i(Vector3(my_tile-target).normalized())
      var res: ResolutionCommand = GridManager.inst.submit_move_attempt(tile, next, exec_ctx)
      exec_ctx.register_resolution(res)
