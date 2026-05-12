extends RefCounted
class_name PointSource

signal received
signal fx_finished

# where the stars should animate towards
var target_point: Vector3

var current: int = 0:
  set(val):
    current = maxi(0, val)
  get:
    return current

func give(amt: int):
  if amt == 0: return
  
  current += amt
  received.emit()

func notify_fx_finished():
  fx_finished.emit()
