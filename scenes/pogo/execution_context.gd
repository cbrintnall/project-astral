extends RefCounted
class_name ExecutionContext

var active_round := false
var tile_execution_count := 0
var collision_data: TileCollisionContext
var initiator: Tile

var resolutions := []

# For events like ON_PLACE, dictates who triggered it
func set_initiator(tile: Tile):
  initiator = tile

func start_execution():
  resolutions.push_back([])

func register_resolution(res: ResolutionCommand):
  resolutions.front().push_back(res)
