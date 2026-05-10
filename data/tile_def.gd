extends Resource
class_name TileDef

@export var name: String = "NEEDS NAME"
@export var shop_cost := 1
@export var execute_directions: Array[Vector2i] = [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]
@export var initiates := false
@export var effects: Array[TileEffect] = []
@export var texture: Texture2D
@export var constellation: ConstellationDef

@export_category("editor")
@export var in_shop := false
@export var is_enemy := false

func get_target_points(ctx: EffectContext) -> Array:
  var targets = effects \
    .filter(func(effect: TileEffect): return effect.target != null) \
    .map(func(effect: TileEffect): return effect.target.get_target(ctx))
  
  return Utils.flatten_array(targets) 
