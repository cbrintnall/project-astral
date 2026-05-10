extends Label3D
class_name NotificationLabel

static func from(txt: String, parent: Node3D) -> NotificationLabel:
  var label = load("res://scenes/board/notification_label.tscn").instantiate()
  label.text = txt
  parent.add_child(label)
  return label
  
func _ready() -> void:
  pixel_size = 0.001
  var t = create_tween()
  t.tween_property(self, "offset", Vector2.DOWN*randf_range(200.0, 300.0), 2.0).set_trans(Tween.TRANS_CUBIC)
  t.parallel().tween_property(self, "pixel_size", 0.005, 1.0).set_trans(Tween.TRANS_BACK)
  t.tween_interval(2.0)
  t.tween_property(self, "transparency", 1.0, 2.0)
  t.tween_callback(queue_free)
