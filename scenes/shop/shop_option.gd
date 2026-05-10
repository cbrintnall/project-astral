extends Marker3D
class_name ShopOption

@onready var text: Label3D = $Label3D

var current: Tile

func _ready() -> void:
  Springer.register("scale", text, Vector3.ONE, Vector3.ZERO, 200.0, 20.0)

func _process(delta: float) -> void:
  Springer.data[text]["scale"]["target"] = Vector3.ONE if current else Vector3.ONE*0.001

func generate():
  if current:
    current.queue_free()
    
  current = load("res://scenes/board/tile.tscn").instantiate()
  var data:TileDef = TileHand.tiles.pick_random()
  
  current.def = data
  add_child(current)
  
  current.set_display_mode()
  text.text = str(data.shop_cost)
