extends RefCounted
class_name GridContext

var points_multipliers = 0.0
var points_additional = 0
var point_source_override: PointSource = null

func get_point_source() -> PointSource:
  if point_source_override:
    return point_source_override
    
  return GameManager.inst.point_source
