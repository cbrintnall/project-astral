extends CycleEffect
class_name CycleEffectSpawnEnemies

@export var range := Vector2i(1,2)

func get_description() -> String:
  return "Nyx will summon between %d to %d enemy tiles adjacent to your tiles." % [range.x,range.y]
  
func on_cycle_start():
  var played = GridManager.inst.get_played_tiles().filter(func(tile: Tile): return not (tile.def.initiates and not tile.def.is_enemy))
  var enemy_tiles = AllTileContainer.inst.resources.filter(func(def: TileDef): return def.is_enemy)
  
  played.shuffle()
  var amount = randi_range(range.x,range.y)
  var spawned := 0
  var enemy_queue := {}

  for i in 1000:
    if spawned > amount or not played: break

    var spot = (played.pop_front() as Tile).get_open_neighbor()
    if spot:
      var data = enemy_tiles.pick_random()
      enemy_queue[spot] = data
      spawned += 1
  
  while enemy_queue:
    var next = enemy_queue.keys().front()
    var tile = load("res://scenes/board/tile.tscn").instantiate()
    tile.faction = Tile.Faction.ENEMY
    tile.def = enemy_queue[next]
    GridManager.inst.try_place_tile(tile, next)
    enemy_queue.erase(next)
    await GameManager.inst.get_tree().create_timer(0.5).timeout
