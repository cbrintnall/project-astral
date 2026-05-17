@tool
extends ResourceCache
class_name ImbuementContainer

static var inst: ImbuementContainer

func is_resource(resource: Resource) -> bool:
  return resource is ImbuementDef

func _ready() -> void:
  inst = self
