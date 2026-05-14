extends RefCounted
class_name GridContext

var points_multipliers = 0.0
var points_additional = 0
var point_source_override: PointSource = null

func get_point_source() -> PointSource:
  if point_source_override and point_source_override.current < point_source_override.target:
    return point_source_override
    
  return GameManager.inst.point_source

func has_mult() -> bool:
  if not is_zero_approx(points_multipliers):
    return true

  if not is_zero_approx(points_additional):
    return true
    
  return false
    
func has_information() -> bool:
  if point_source_override:
    return true
    
  return false
