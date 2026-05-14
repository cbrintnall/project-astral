extends Node
class_name HandManager

static var inst: HandManager

var hand := []
var discard := []

func _ready() -> void:
  inst = self

  for tile in Constants.START_DECK.duplicate():
    add_tile(tile)
  
func add_tile(tile: TileDef):
  discard.push_back(tile.duplicate())
  
func return_to_discard(tile: TileDef):
  discard.push_back(tile)
  
func get_next_from_hand() -> TileDef:
  if not hand:
    hand.append_array(discard)
    hand.shuffle()
    discard = []

  return hand.pop_front()
