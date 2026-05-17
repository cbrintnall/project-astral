extends Node
class_name MusicManager

@export var player: AudioStreamPlayer

@onready var reverb: AudioEffectReverb = AudioServer.get_bus_effect(AudioServer.get_bus_index("Music"), 0)
@onready var chorus: AudioEffectChorus = AudioServer.get_bus_effect(AudioServer.get_bus_index("Music"), 1)

var _restart_time := BetterTimer.new(0.0)

func _ready() -> void:
  _restart_time.bind_reset(func(): return randf_range(30.0, 120.0))

func _process(delta: float) -> void:
  if not player.playing and _restart_time.check(delta):
    player.play()
  
  match GameManager.inst.current_state:
    "end_game":
      if not GameManager.inst.won:
        player.pitch_scale = move_toward(player.pitch_scale, 0.1, 0.05)
      else:
        chorus.wet = move_toward(chorus.wet, 1.0, 0.05)
    _:
      player.pitch_scale = move_toward(player.pitch_scale, 1.0, delta)
      chorus.wet = move_toward(chorus.wet, 0.0, delta)
