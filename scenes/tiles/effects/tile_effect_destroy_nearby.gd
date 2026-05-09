extends TileEffect
class_name TileEffectDestroyNearby

@export var directions : Array[Vector3i] = []

func _ready() -> void:
  event = TileEffect.Event.ON_ROUND_START
  
func _get_directional_text(dir: Vector3i) -> String:
  match dir:
    Vector3i.RIGHT:
      return "right"
    Vector3i.LEFT:
      return "left"
    Vector3i.FORWARD:
      return "above"
    Vector3i.BACK:
      return "below"
  return "<INVALID DIRECTION>"
  
func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  var direction_indicators = directions.map(_get_directional_text)
  return "Destroys the tiles: %s" % [ ", ".join(direction_indicators) ]
  
func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  var pos = GridManager.inst.get_tile_loc(effect_ctx.tile)
  var t = create_tween()
  for dir in directions:
    var target = pos+dir
    t.tween_property(
      effect_ctx.tile,
      "global_position",
      effect_ctx.tile.global_position+(Vector3(dir)*0.6),
      0.2
    ).set_trans(Tween.TRANS_BACK)
    t.tween_callback(
      func():
        var tile: Tile = GridManager.inst.get_tile_at(target)
        if tile and not tile.def.initiates:
          AudioManager3d.play({
            "stream": preload("res://audio/break-tile.ogg"),
            "pitch_variance": 0.05,
            "location": tile.global_position
          })
          tile.queue_free()
          print("TODO: destroy fx, maybe dissolve shader?")
    )
    var tile: Tile = GridManager.inst.get_tile_at(target)
    if tile:
      t.tween_interval(0.5)
    t.tween_property(
      effect_ctx.tile,
      "global_position",
      effect_ctx.tile.global_position,
      0.2
    ).set_trans(Tween.TRANS_BACK)
    t.tween_interval(0.2)
  await t.finished
