extends TileEffect
class_name TileEffectDestroyMarked

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "Destroy any tile in the marked areas."
  
func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  for target: Vector3i in main_target.get_target(effect_ctx):
    var tile: Tile = GridManager.inst.get_tile_at(target)
    if tile:
      tile.destroy()
