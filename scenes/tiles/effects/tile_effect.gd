@abstract
extends Resource
class_name TileEffect

enum Event {
  ON_ACTIVATE = 1,
  ON_ROUND_START = 2,
  ON_ROUND_END = 4,
  ON_DESTROY = 8,
  ON_PLACE = 16
}

@export var event := Event.ON_PLACE
@export var main_target: TileTargetDef

func get_event_text() -> String:
  match event:
    Event.ON_ACTIVATE:
      return "[color=#f2d3ab]On Activate[/color]"
    Event.ON_ROUND_START:
      return "On Round Start"
    Event.ON_ROUND_END:
      return "On Round End"
    Event.ON_DESTROY:
      return "On Destroyed"
    Event.ON_PLACE:
      return "On Placed"

  return "ERROR, NO EVENT"

@abstract func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String
@abstract func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext)

func run(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  for i in roundi(effect_ctx.tile.stat.get_value(preload("res://data/stats/stat_replay.tres")))+1:
    await execute(effect_ctx, exec_ctx)

func _reward_points(effect_ctx: EffectContext, amount: int):
  var total_points = _get_total_points(effect_ctx, amount)
  GameManager.inst.current_score += total_points
  NotificationLabel.from("%+d" % total_points, effect_ctx.tile)
  if total_points <= 0: return
  var stars: MultiMeshInstance3D = load("res://scenes/fx/stars_multimesh.tscn").instantiate()
  effect_ctx.tile.get_tree().current_scene.add_child(stars)
  stars.multimesh = stars.multimesh.duplicate()
  stars.multimesh.instance_count = total_points
  var t = effect_ctx.tile.get_tree().current_scene.create_tween()
  for i in total_points:
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

func _get_total_points(effect_ctx: EffectContext, base_amount: int) -> int:
  if not effect_ctx.tile.placed:
    return base_amount
  var grid_ctx := GridManager.inst.get_mods_at_point(GridManager.inst.get_tile_loc(effect_ctx.tile))
  var added_points = base_amount+grid_ctx.points_additional
  var total_points = floori(added_points+(added_points*grid_ctx.points_multipliers))
  return total_points
