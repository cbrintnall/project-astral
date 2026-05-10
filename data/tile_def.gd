extends Resource
class_name TileDef

@export var name: String = "NEEDS NAME"
@export var shop_cost := 1
@export var execute_directions: Array[Vector2i] = [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]
@export var initiates := false
@export var effects: Array[TileEffect] = []
@export var texture: Texture2D
@export var constellation: ConstellationDef
