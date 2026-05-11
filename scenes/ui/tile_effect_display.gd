extends MarginContainer
class_name EffectsDisplayRoot

@onready var event_text: RichTextLabel = %EventText
@onready var event_description: RichTextLabel = %Description

var effect_ctx: EffectContext

var effect: TileEffect:
  set(val):
    if val == effect:
      return
      
    effect = val
  get:
    return effect
    
func _ready() -> void:
  if not effect:
    queue_free()
    set_process(false)

func _process(delta: float) -> void:
  if not is_instance_valid(effect_ctx.tile):
    return 
  
  if effect:
    event_text.text = effect.get_event_text()
    event_description.text = effect.get_description(effect_ctx, GameManager.inst.active_execution)
    
  
