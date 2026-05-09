@abstract
extends Node3D
class_name TileEffect

enum Event {
  ON_ACTIVATE,
  ON_ROUND_START,
  ON_ROUND_END,
  ON_DESTROY  
}

@export var event := Event.ON_ACTIVATE

@abstract func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String
@abstract func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext)
