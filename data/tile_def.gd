extends Resource
class_name TileDef

@export var execute_directions: Array[Vector2i] = [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]
@export var initiates := false
@export var effects: Array[TileEffect] = []
@export var texture: Texture2D
