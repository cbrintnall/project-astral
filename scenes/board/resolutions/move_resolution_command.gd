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
  if tile.def.initiates:
    return false
  
  if attempts.get(target, Set.new()).count() <= 1:
    return true

  return false

func execute():
  var prev = max_resolution_count
  max_resolution_count = maxi(max_resolution_count, _count)
  
  # Keep track of the highest resolutions, for stat purposes
  if max_resolution_count > prev:
    print("new move resolution max, %d" % max_resolution_count)
  
  if not GridManager.inst.try_move(tile, target):
    if _count < Constants.MAX_RESOLUTIONS_BEFORE_GIVE_UP:
      _count += 1
      context.register_resolution(self)
    else:
      push_warning("Movement resolution gave up, hit max resolution count (tile=%s).." % tile.def.name)
  
func undo():
  tile.stretcher.punch(10.0, 15.0)
