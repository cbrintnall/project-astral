@tool
extends ResourceCache
class_name ShopTileContainer

static var inst: ShopTileContainer

func _ready() -> void:
  inst = self

func is_resource(resource: Resource) -> bool:
  return resource is TileDef and resource.in_shop
