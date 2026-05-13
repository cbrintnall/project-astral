extends TileEffect
class_name TileEffectGiveTile

enum Location {
  HAND = 0,
  DECK = 1
}

@export var location := Location.HAND
@export var def: TileDef

func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String:
  return "Adds tile \"[color=#c69fa5]%s[/color]\" to your %s" % [ def.name, "hand" if location == Location.HAND else "stash" ]

func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext):
  match location:
    Location.HAND:
      TileHand.inst.add_to_hand(def)
    Location.DECK:
      HandManager.inst.add_tile(def)
