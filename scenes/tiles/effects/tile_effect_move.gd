@tool
extends TileEffect
class_name TileEffectMove

enum TargetPicker {
  FIRST = 0,
  RANDOM = 1
}

@export var move_target: TileTargetDef
@export var target_picker := TargetPicker.FIRST

# Defaults to moving itself
func _init() -> void:
  main_target = TileTargetDef.new()
  main_target.include_self = true
  
  move_target = TileTargetDef.new()

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "Moves %s to %s" % [ main_target.get_text(), move_target.get_text() ]

func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  for target: Vector3i in main_target.get_target(effect_ctx):
    var tile: Tile = GridManager.inst.get_tile_at(target)
    var prev_override := effect_ctx.override_location
    effect_ctx.override_location = target
    var target_tiles := move_target.get_target(effect_ctx)
    effect_ctx.override_location = prev_override
    if target_tiles and tile:
      match target_picker:
        TargetPicker.FIRST:
          var res: ResolutionCommand = GridManager.inst.submit_move_attempt(tile, target_tiles.front(), exec_ctx)
          exec_ctx.register_resolution(res)
        TargetPicker.RANDOM:
          var res: ResolutionCommand = GridManager.inst.submit_move_attempt(tile, target_tiles.pick_random(), exec_ctx)
          exec_ctx.register_resolution(res)
