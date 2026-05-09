extends TileEffect
class_name TileEffectGivePoints

@export var points_given := 1

func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  GameManager.inst.current_score += points_given
  AudioManager3d.play({
    "stream": preload("res://audio/Light Drone Sound (button hover) 34.wav"),
    "parent": self
  })
  var stars: MultiMeshInstance3D = load("res://scenes/fx/stars_multimesh.tscn").instantiate()
  effect_ctx.tile.get_tree().current_scene.add_child(stars)
  stars.multimesh = stars.multimesh.duplicate()
  stars.multimesh.instance_count = points_given
  var t = effect_ctx.tile.create_tween()
  for i in points_given:
    t.set_parallel(true)
    var end = GridManager.inst.center_tile.global_position
    var offset = (Vector3.ONE*randf())*(Vector3(1.0, 0.0, 1.0)).normalized()
    var start = effect_ctx.tile.global_position+Vector3.UP+offset
    var star_scale = randf_range(0.25, 0.6)
    t.tween_method(
      func(time: float):
        var pt = start.lerp(end, time)
        pt += preload("res://data/curves/curve_star_height_offset.tres").sample(time)*Vector3.UP*5.0
        var target := Transform3D().scaled(Vector3.ONE*star_scale).translated(pt)
        stars.multimesh.set_instance_transform(i, target)
        if time >= 1.0:
          GameManager.inst.do_receive_points_fx()
        ,
      0.0,
      1.0,
      randf_range(1.0, 2.0)
    ).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
  t.set_parallel(false)
  t.tween_callback(stars.queue_free)
  await effect_ctx.tile.get_tree().create_timer(0.2).timeout
  
func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "Creates %d dawn." % points_given
