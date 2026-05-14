extends ResolutionCommand
class_name MoveResolutionCommand

static var max_resolution_count := 0

var attempts := {}
var tile: Tile
var target: Vector3i

func cleanup():
  if attempts.has(target):
    attempts[target].remove(tile)

func check():
  if state != ResolutionState.WAITING:
    return
  
  if not is_instance_valid(tile):
    state = ResolutionState.FAILED
    return
  
  if tile.def.initiates:
    state = ResolutionState.FAILED
    return

  if attempts.get(target, Set.new()).count() > 1:
    state = ResolutionState.SHOULD_DEFER
    return
  
  if not GridManager.inst.could_place(tile, target):
    state = ResolutionState.SHOULD_DEFER
    return
    
  state = ResolutionState.CAN_EXECUTE

func execute():
  assert(GridManager.inst.try_place_tile(tile, target), "Check step failed but made it to execution")
  
func undo():
  if is_instance_valid(tile):
    tile.stretcher.punch(10.0, 15.0)
  
func deadlock():
  tile.notify_failed_move(target, attempts)
