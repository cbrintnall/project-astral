extends Node
class_name VfxManager

static var inst: VfxManager

func _ready() -> void:
  inst = self
  
func do_ranged_effect(from: Vector3, to: PackedVector3Array, height_offset := 3.0, ctx := VfxContext.new()):
  var start_pos = from
  var tween := create_tween()
  
  for i in len(to):
    var pt: Vector3 = to[i]
    var fx = load("res://scenes/fx/chip_bolt_fx.tscn").instantiate()
    add_child(fx)
    tween.parallel().tween_method(
      func(time: float):
        var offset = preload("res://data/curves/curve_chip_bolt_offset.tres").sample(time)*Vector3.UP*height_offset
        fx.global_position = start_pos.lerp(Vector3(pt), time)+offset
        if time >= 1.0:
          ctx.on_step.emit(i)
          fx.queue_free()
        ,
      0.0,
      1.0,
      randf_range(ctx.duration_range.x, ctx.duration_range.y)
    ).set_delay(randf_range(ctx.delay_range.x, ctx.delay_range.y)).set_trans(ctx.transition)

  tween.finished.connect(ctx.on_finish.emit)
