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

func get_event_text() -> String:
  match event:
    Event.ON_ACTIVATE:
      return "[color=#f2d3ab]On Activate[/color]"
    Event.ON_ROUND_START:
      return "On Round Start"
    Event.ON_ROUND_END:
      return "On Round End"
    Event.ON_DESTROY:
      return "On Destroyed"

  return "ERROR, NO EVENT"

@abstract func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String
@abstract func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext)
