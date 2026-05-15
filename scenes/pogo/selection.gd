extends RefCounted
class_name Selection

enum State {
  DEFAULT,
  VALID,
  WARNING,
  ERROR
}

signal canceled 
signal started

var state := State.DEFAULT
var can_cancel := true
var _is_canceled := false

var on_choose: Callable
var on_process: Callable

func cancel():
  if _is_canceled: return
  
  _is_canceled = true
  canceled.emit()
