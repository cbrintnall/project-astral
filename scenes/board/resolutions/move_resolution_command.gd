extends ResolutionCommand
class_name MoveResolutionCommand

static var max_resolution_count := 0

var attempts := {}
var tile: Tile
var target: Vector3i

var _count := 0

func cleanup():
  if attempts.has(target):
    attempts[target].remove(tile)

func check() -> bool:
  if not is_instance_valid(tile):
    return false
  
  if tile.def.initiates:
    return false

  return true

func execute():
  max_resolution_count = maxi(max_resolution_count, _count)
  
  var tile_over_claimed = attempts.get(target, Set.new()).count() > 1
  
  if tile_over_claimed:
    _try_defer_eval()
    return
    
  if not GridManager.inst.try_place_tile(tile, target):
    _try_defer_eval()
  else:
    attempts.get(target, Set.new()).remove(target)
  
func undo():
  if is_instance_valid(tile):
    tile.stretcher.punch(10.0, 15.0)
  
func _try_defer_eval():
  if _count < Constants.MAX_RESOLUTIONS_BEFORE_GIVE_UP:
    _count += 1
    context.register_resolution(self)
  else:
    tile.notify_failed_move(target, attempts)
