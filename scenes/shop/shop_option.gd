extends Marker3D
class_name ShopOption

enum ShopType {
  TILE,
  TILE_PACK,
  IMBUEMENT,
  REMOVAL
}

@export var type := ShopType.TILE

@onready var text: Label3D = $ShopLabel

var current: Node3D

func _ready() -> void:
  Springer.register("scale", text, Vector3.ONE, Vector3.ZERO, 200.0, 20.0)

func _process(delta: float) -> void:
  Springer.data[text]["scale"]["target"] = Vector3.ONE if current else Vector3.ONE*0.001

func generate():
  if current:
    current.queue_free()
  
  match type:
    ShopType.TILE:
      generate_tile()
    ShopType.TILE_PACK:
      generate_tile_pack()
    ShopType.IMBUEMENT:
      generate_imbuement()
    
func generate_imbuement():
  current = load("res://scenes/shop/imbuement_option.tscn").instantiate()
  current.ready.connect(
    func():
      text.text = str(current.cost)
  )
  add_child(current)
      
func generate_tile_pack():
  current = load("res://scenes/shop/tile_pack.tscn").instantiate()
  current.ready.connect(
    func():
      text.text = str(current.cost)
  )
  add_child(current)

func generate_tile():
  current = load("res://scenes/board/tile.tscn").instantiate()
  var data:TileDef = ShopTileContainer.inst.resources.pick_random()
  
  current.def = data
  add_child(current)
  
  current.set_display_mode()
  text.text = str(data.shop_cost)
