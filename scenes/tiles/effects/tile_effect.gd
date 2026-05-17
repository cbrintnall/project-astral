@abstract
extends Resource
class_name TileEffect

const EFFECT_COLOR_STRING = ""

enum Event {
  ON_ACTIVATE = 1,
  ON_ROUND_START = 2,
  ON_ROUND_END = 4,
  ON_DESTROY = 8,
  ON_PLACE = 16,
  ON_MOVE = 32,
  ON_COLLIDE_TILE = 64,
  CUSTOM = 128,
  ON_CYCLE_START = 256
}

@export var event := Event.ON_PLACE
@export var main_target: TileTargetDef

func get_event_text() -> String:
  match event:
    Event.ON_ACTIVATE: 
      return "[color=%s]On Activate[/color]" % Constants.EFFECT_COLOR_STRING
    Event.ON_ROUND_START:
      return "[color=%s]On Turn Start[/color]" % Constants.EFFECT_COLOR_STRING
    Event.ON_ROUND_END:
      return "[color=%s]On Turn End[/color]" % Constants.EFFECT_COLOR_STRING
    Event.ON_DESTROY:
      return "On Destroyed"
    Event.ON_PLACE:
      return "On Place"
    Event.ON_MOVE:
      return "[color=%s]On Move[/color]" % Constants.EFFECT_COLOR_STRING
    Event.ON_COLLIDE_TILE:
      return "[color=%s]On Collide Tile[/color]" % Constants.EFFECT_COLOR_STRING
    Event.ON_CYCLE_START:
      return "[color=%s]On Cycle Start[/color]" % Constants.EFFECT_COLOR_STRING

  return "ERROR, NO EVENT"

@abstract func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String
@abstract func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext)

func clone() -> TileEffect:
  return duplicate()

func resolve(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  pass

func run(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  var replays = 1

  if effect_ctx.tile:
    replays = roundi(effect_ctx.tile.stat.get_value(preload("res://data/stats/stat_replay.tres")))+1
  
  for i in replays:
    await execute(effect_ctx, exec_ctx)

func would_give_points(effect_ctx: EffectContext) -> bool:
  return _get_total_points(effect_ctx, get_tile_baseline_points(effect_ctx))
  
"""
The amount of points this effect will give without any other considerations
"""
func get_tile_baseline_points(effect_ctx: EffectContext) -> int:
  return 0

func _reward_points(effect_ctx: EffectContext, amount: int):
  var total_points = _get_total_points(effect_ctx, amount)
  var first_source: PointSource = GridManager.inst.get_mods_at_point(effect_ctx.get_location()).get_point_source()
  var remaining = first_source.give(total_points)
  var second_source = GridManager.inst.get_mods_at_point(effect_ctx.get_location()).get_point_source()
  var final_remaining = second_source.give(remaining)
  assert(final_remaining <= 0, "Not sure why this would happen but it probably can")
  NotificationLabel.from("%+d" % total_points, effect_ctx.tile)

  var first_animation = total_points-remaining
  if first_animation > 0:
    _animate_points_to_source(first_source, first_animation, effect_ctx.tile)
  
  if remaining > 0:
    _animate_points_to_source(second_source, remaining-final_remaining, effect_ctx.tile)
  
func _animate_points_to_source(src: PointSource, amount: int, tile: Tile):
  var stars: MultiMeshInstance3D = load("res://scenes/fx/stars_multimesh.tscn").instantiate()
  tile.get_tree().current_scene.add_child(stars)
  stars.multimesh = stars.multimesh.duplicate()
  stars.multimesh.instance_count = amount
  var t = tile.get_tree().current_scene.create_tween()
  for i in amount:
    t.set_parallel(true)
    var end = src.target_point
    var offset = (Vector3.ONE*randf())*(Vector3(1.0, 0.0, 1.0)).normalized()
    var start = tile.global_position+Vector3.UP+offset
    var star_scale = randf_range(0.25, 0.6)
    t.tween_method(
      func(time: float):
        var pt = start.lerp(end, time)
        pt += preload("res://data/curves/curve_star_height_offset.tres").sample(time)*Vector3.UP*5.0
        var target := Transform3D().scaled(Vector3.ONE*star_scale).translated(pt)
        stars.multimesh.set_instance_transform(i, target)
        if time >= 1.0:
          src.notify_fx_finished()
        ,
      0.0,
      1.0,
      randf_range(1.0, 2.0)
    ).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
  t.set_parallel(false)
  t.tween_callback(stars.queue_free)

func _get_total_points(effect_ctx: EffectContext, base_amount: int) -> int:
  var src_loc = effect_ctx.override_location
  
  if not src_loc and effect_ctx.tile:
    src_loc = GridManager.inst.get_tile_loc(effect_ctx.tile)
  
  var grid_ctx := GridManager.inst.get_mods_at_point(src_loc)
  var added_points = base_amount+grid_ctx.points_additional
  
  if effect_ctx.tile:
    added_points += effect_ctx.tile.stat.get_value(preload("res://data/stats/stat_additional_points.tres"))
  
  if not effect_ctx.tile or not effect_ctx.tile.placed:
    src_loc = effect_ctx.override_location
  
  var total_points = floori(added_points+(added_points*grid_ctx.points_multipliers))
  return total_points
