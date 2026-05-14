extends RefCounted
class_name PointSource

signal received
signal fx_finished

# where the stars should animate towards
var target_point: Vector3

var target := 0
var current: int = 0:
  set(val):
    current = maxi(0, val)
  get:
    return current

func give(amt: int) -> int:
  if amt == 0: return 0
  
  if target > 0:
    var taking := mini(amt, target-current)
    current += taking
    return amt-taking
  else:
    current += amt

  received.emit()
  return 0

func notify_fx_finished():
  fx_finished.emit()
