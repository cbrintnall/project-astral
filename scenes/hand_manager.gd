extends Node
class_name HandManager

static var inst: HandManager

enum Deck {
  HAND = 0,
  DISCARD = 1
}

var all_tiles := []
var imbuements := []
var hand := []
var discard := []

func _ready() -> void:
  inst = self

  for tile in Constants.START_DECK.duplicate():
    add_tile(tile)
    
  try_give_imbuement(load("res://data/imbuements/imbuement_basic_heal.tres"))
  try_give_imbuement(load("res://data/imbuements/imbuement_basic_defense.tres"))
    
  Console.add_command(
    "hands",
    func():
      Console.print_line("Hand (%d): %s" % [len(hand), ", ".join(hand.map(func(tile: TileDef): return tile.name))])
      Console.print_line("Discard (%d): %s" % [len(discard), ", ".join(discard.map(func(tile: TileDef): return tile.name))])
  )
  
  Console.add_command(
    "imbuement",
    func(path: String):
      try_give_imbuement(load(path)),
    ["path"]
  )
  
func get_imbuement_at_idx(idx: int) -> ImbuementDef:
  if idx < 0:
    return null
  
  if idx >= len(imbuements):
    return null
    
  return imbuements[idx]
  
func try_give_imbuement(imbuement: ImbuementDef) -> bool:
  if len(imbuements) >= 5:
    return false
    
  imbuements.push_back(imbuement.duplicate())
  return true
    
func get_tile_at_idx(deck: Deck, idx: int) -> TileDef:
  if idx < 0:
    return null
  
  match deck:
    Deck.HAND:
      if idx >= len(hand): return null
      return hand[idx]
    Deck.DISCARD:
      if idx >= len(discard): return null
      return discard[idx]
  
  return null
  
func get_deck_size(deck: Deck) -> int:
  match deck:
    Deck.HAND:
      return len(hand)
    Deck.DISCARD:
      return len(discard)
  return 0
  
func remove_tile(tile: TileDef):
  assert(tile in all_tiles)
  all_tiles.erase(tile)
  discard.erase(tile)
  hand.erase(tile)
  TileHand.inst.remove_tile(tile)
  
func add_tile(tile: TileDef):
  var incoming := tile.duplicate()
  all_tiles.push_back(incoming)
  discard.push_back(incoming)
  
func return_to_discard(tile: TileDef):
  discard.push_back(tile)
  
func get_next_from_hand() -> TileDef:
  if not hand:
    hand.append_array(discard.duplicate())
    hand.shuffle()
    discard = []

  return hand.pop_front()
