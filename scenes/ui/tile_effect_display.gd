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
      
    if is_inside_tree():
      event_text.text = effect.get_event_text()
      event_description.text = effect.get_description(effect_ctx, GameManager.inst.active_execution)
    else:
      ready.connect(
        func():
          event_text.text = effect.get_event_text()
          event_description.text = effect.get_description(effect_ctx, GameManager.inst.active_execution)
      )
  get:
    return effect
