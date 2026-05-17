@tool
extends ResourceCache
class_name RealImbuementContainer

static var inst: RealImbuementContainer

func _ready() -> void:
  inst = self

func is_resource(resource: Resource) -> bool:
  return resource is TileEffect and resource.resource_path.contains("imbuement_effects")
