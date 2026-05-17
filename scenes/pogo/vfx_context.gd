extends RefCounted
class_name VfxContext

signal on_finish
signal on_step(idx: int)
signal on_step_started(idx: int)

var duration_range := Vector2.ONE
var delay_range := Vector2.ZERO
var transition := Tween.TransitionType.TRANS_CUBIC
