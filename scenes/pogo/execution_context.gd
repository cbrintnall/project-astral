extends RefCounted
class_name ExecutionContext

var active_round := false
var tile_execution_count := 0

var resolutions := []

func start_execution():
  resolutions.push_back([])

func register_resolution(res: ResolutionCommand):
  resolutions.front().push_back(res)
