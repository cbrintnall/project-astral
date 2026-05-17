extends MarginContainer
class_name EffectsDisplayRoot

@onready var event_text: RichTextLabel = %EventText
@onready var event_description: RichTextLabel = %Description
@onready var area_tags: Control = %AreaTagsRoot

var effect_ctx: EffectContext
var hide_trigger := false

var effect: TileEffect:
  set(val):
    if val == effect:
      return
      
    effect = val
    _sync_tags()
  get:
    return effect
    
func _ready() -> void:
  visible = false
  
  if not effect:
    queue_free()
    set_process(false)
    
  get_tree().process_frame.connect(func(): visible = true, CONNECT_ONE_SHOT)

func _sync_tags():
  NodeUtils.clear_children(%AreaTagsRoot)
  if effect.main_target:
    var tags := effect.main_target.get_text_tags()
    for tag: String in tags:
      var area_tag = load("res://scenes/ui/area_tag.tscn").instantiate()
      var rich_text: RichTextLabel = NodeUtils.collect_children(area_tag, "RichTextLabel")["RichTextLabel"]
      rich_text.text = tag
      %AreaTagsRoot.add_child(area_tag)

func _process(_delta: float) -> void:
  %EventTextRoot.visible = effect.event != TileEffect.Event.CUSTOM and not hide_trigger
  var final_points = effect.get_current_dawn_amount(effect_ctx)
  %TileAmount.visible = not is_zero_approx(final_points)
  %TileAmount.text = "Total Dawn: %d" % final_points
  if effect:
    event_text.text = effect.get_event_text()
    event_description.text = effect.get_description(effect_ctx, GameManager.inst.active_execution)
    
  
