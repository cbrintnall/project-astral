extends RefCounted
class_name Selection

signal canceled 
signal started

var can_cancel := true
var _is_canceled := false

var on_choose: Callable

func cancel():
  if _is_canceled: return
  
  _is_canceled = true
  canceled.emit()
