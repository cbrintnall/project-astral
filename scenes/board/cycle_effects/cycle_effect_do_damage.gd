extends CycleEffect
class_name CycleEffectGiveChip

var _all_tiles = preload("res://data/targets/tile_target_all_tiles.tres")
var _damage := 5

func get_description() -> String:
  return "Nyx will fire arrows at all tiles, dealing %d damage." % _damage

func on_cycle_start():
  var targets = _all_tiles.get_target(EffectContext.new(), true)
  var context := VfxContext.new()
  
  context.on_step.connect(func(idx: int): GridManager.inst.get_tile_at(targets[idx]).do_chip_damage(_damage))
  context.delay_range = Vector2(0.1, 1.0)
  context.duration_range = Vector2(1.0, 2.0)
  context.transition = Tween.TransitionType.TRANS_QUAD
  
  VfxManager.inst.do_ranged_effect(
    Vector3.RIGHT*(GridManager.inst.size.x * 3.0),
    targets,
    30.0,
    context,
  )
