extends Node
class_name HandManager

static var inst: HandManager

var hand := []
var discard := []

func _ready() -> void:
  inst = self
  
  hand = Constants.START_DECK.duplicate()
  
func add_tile(tile: TileDef):
  hand.push_back(tile)
  
func get_next_from_hand() -> TileDef:
  return hand.pick_random()
