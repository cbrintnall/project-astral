extends Node
class_name VfxManager

static var inst: VfxManager

func _ready() -> void:
  inst = self
  
func do_ranged_effect(from: Vector3, to: PackedVector3Array, height_offset := 3.0, ctx := VfxContext.new()):
  if len(to) <= 0:
    ctx.on_finish.emit()
    return
  
  var start_pos = from
  var tween := create_tween()
  
  for i in len(to):
    var pt: Vector3 = to[i]
    var fx: Node3D = load("res://scenes/fx/chip_bolt_fx.tscn").instantiate()
    add_child(fx)
    var delay := randf_range(ctx.delay_range.x, ctx.delay_range.y)
    var tweener := tween.parallel().tween_method(
      func(time: float):
        var offset = preload("res://data/curves/curve_chip_bolt_offset.tres").sample(time)*Vector3.UP*height_offset
        var current = fx.global_position
        var next = start_pos.lerp(Vector3(pt), time)+offset
        var dir = current.direction_to(next)
        fx.global_basis.slerp(Basis.looking_at(-dir), 0.1)
        fx.global_position = next,
      0.0,
      1.0,
      randf_range(ctx.duration_range.x, ctx.duration_range.y)
    ).set_delay(delay).set_trans(ctx.transition)
    
    get_tree().create_timer(delay).timeout.connect(ctx.on_step_started.emit.bind(i))
    
    tweener.finished.connect(
      func():
        ctx.on_step.emit(i)
        fx.queue_free()
    )

  tween.finished.connect(ctx.on_finish.emit)

func do_light_beam(point: Vector3, ctx := VfxContext.new()):
  var tween := create_tween()
  var start_pos = point + (Vector3.UP*1000.0)
  
  var fx: Path3D = load("res://scenes/fx/vfx_light_beam.tscn").instantiate()
  add_child(fx)
  var tweener := tween.tween_method(
    func(time: float):
      fx.curve.set_point_position(1, fx.to_local(start_pos))
      fx.global_position = start_pos.lerp(point, time),
    0.0,
    1.0,
    randf_range(ctx.duration_range.x, ctx.duration_range.y)
  ).set_delay(randf_range(ctx.delay_range.x, ctx.delay_range.y)).set_trans(ctx.transition)

  tweener.finished.connect(
    func():
      ctx.on_step.emit(-1)
      fx.queue_free()
  )

  tween.finished.connect(ctx.on_finish.emit)
  
func do_icons_at(mesh: Mesh, points: PackedVector3Array, height := 1.0, ctx := VfxContext.new()):
  if len(points) <= 0:
    ctx.on_finish.emit()
    return

  var highlighter := GridHighlights.new()
  highlighter.mesh = mesh
  highlighter.spots.resize(len(points))
  highlighter.spots.fill(Vector3.ZERO)
  add_child(highlighter)
  var tween := create_tween()

  for i in len(points):
    var start_pos := points[i]
    var pt: Vector3 = start_pos + (Vector3.UP * height)
    var delay := randf_range(ctx.delay_range.x, ctx.delay_range.y)
    var tweener := tween.parallel().tween_method(
      func(time: float):
        highlighter.spots[i] = start_pos.lerp(pt, time),
      0.0,
      1.0,
      randf_range(ctx.duration_range.x, ctx.duration_range.y)
    ).set_delay(delay).set_trans(ctx.transition)
    
    get_tree().create_timer(delay).timeout.connect(ctx.on_step_started.emit.bind(i))
    
    tweener.finished.connect(
      func():
        ctx.on_step.emit(i)
    )
    
  tween.tween_interval(2.0)

  tween.finished.connect(
    func():
      highlighter.queue_free()
      ctx.on_finish.emit()
  )
