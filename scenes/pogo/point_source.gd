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
    
var _sound_counter := 0.0
var _last_given := 0.0

func _init() -> void:
  pass

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
  _do_given_fx()
  fx_finished.emit()

func _update_last_given():
  var seconds := (Time.get_ticks_msec()*1000.0)
  if (seconds-_last_given) > 1.0:
    _last_given = seconds

func _do_given_fx():
  _sound_counter += 0.01
  
  AudioManager3d.play({
    "stream": preload("res://audio/Light Drone Sound (button hover) 9.wav"),
    "pitch_additional": _sound_counter,
    "debounce": 0.05,
    "location": target_point
  })
  
  _update_last_given()
