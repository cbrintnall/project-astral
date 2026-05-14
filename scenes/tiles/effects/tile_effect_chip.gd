@tool
extends TileEffect
class_name TileEffectChip

@export var amount := 1
  
func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "Chip the marked tiles by %d. Chip damages tiles if their chip is higher than defense." % [ amount ]
  
func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  var targets = main_target.get_target(effect_ctx)
  var tween := effect_ctx.tile.create_tween()
  for target: Vector3i in targets:
    if not GridManager.inst.get_tile_at(target): continue
    var fx = load("res://scenes/fx/chip_bolt_fx.tscn").instantiate()
    effect_ctx.tile.add_child(fx)
    var start_pos = effect_ctx.tile.global_position+Vector3.UP
    
    tween.parallel().tween_method(
      func(time: float):
        var offset = preload("res://data/curves/curve_chip_bolt_offset.tres").sample(time)*Vector3.UP*3.0
        fx.global_position = start_pos.lerp(Vector3(target), time)+offset
        if time >= 1.0:
          fx.queue_free()
          GridManager.inst.get_tile_at(target).stat.add_provider(
            preload("res://data/stats/stat_chip.tres"),
            StatProviderDef.from(amount)
          )
        ,
      0.0,
      1.0,
      randf_range(0.3,0.8)
    ).set_delay(randf_range(0.1, 0.3))
  
  await tween.finished
