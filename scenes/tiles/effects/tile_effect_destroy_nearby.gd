extends TileEffect
class_name TileEffectDestroyNearby

@export var directions : Array[Vector3i] = []

func _ready() -> void:
  event = TileEffect.Event.ON_ROUND_START
  
func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "destroys stuff"
  
func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  print("hello?")
  var pos = GridManager.inst.get_tile_loc(effect_ctx.tile)
  for dir in directions:
    var target = pos+dir
    var tile: Tile = GridManager.inst.get_tile_at(target)
    if tile and not tile.def.initiates:
      tile.queue_free()
      print("TODO: destroy fx, maybe dissolve shader?")
