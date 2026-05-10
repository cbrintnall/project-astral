@tool
extends ResourceCache
class_name EnemyTileContainer

func is_resource(resource: Resource) -> bool:
  return resource is TileDef and resource.is_enemy
