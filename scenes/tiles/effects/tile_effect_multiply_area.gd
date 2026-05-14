extends TileEffect
class_name TileEffectMultiplyArea

@export var size := Vector2i.ONE
@export var multiplier := 2.0

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "Marked tiles give %.0f%% dawn." % [multiplier*100.0]
  
func _update_position_command(effect_ctx: EffectContext):
  var points = main_target.get_target(effect_ctx)
  var cmd := BasicCommand.from(
    func():
      for pt: Vector3i in points:
        var ctx := GridManager.inst.get_mods_at_point(pt)
        ctx.points_multipliers += multiplier
        GridManager.inst.upgrade_grid_context(pt, ctx),
    func():
      for pt: Vector3i in points:
        var ctx := GridManager.inst.get_mods_at_point(pt)
        ctx.points_multipliers -= multiplier
        GridManager.inst.upgrade_grid_context(pt, ctx)
      _update_position_command(effect_ctx)
  )
  
  effect_ctx.tile.register_bind_command(Tile.TileBind.POSITION, cmd)
  cmd.execute()

func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  _update_position_command(effect_ctx)
  
  var lifetime_cmd := BasicCommand.from(
    func(): pass,
    func():
      var points = main_target.get_target(effect_ctx)
      for pt: Vector3i in points:
        var ctx := GridManager.inst.get_mods_at_point(pt)
        ctx.points_multipliers -= multiplier
        GridManager.inst.upgrade_grid_context(pt, ctx)   
  )

  effect_ctx.tile.register_bind_command(Tile.TileBind.LIFETIME, lifetime_cmd)
