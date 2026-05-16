extends Resource
class_name ImbuementDef

@export_category("gameplay")
@export var effects : Array[TileEffect] = []
@export var turn_cooldown := 2

@export_category("meta")
@export var name: String = "Needs Name"
@export var preview_mesh: Mesh
