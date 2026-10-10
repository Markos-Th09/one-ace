extends "res://scripts/components/audio_manager.gd"
const CHIP: AudioStream = preload("res://assets/sfx/Chip Attack Sounds.mp3")
const SLAM: AudioStream = preload("res://assets/sfx/Attack Ground Slam King.mp3")
const SWING: AudioStream = preload("res://assets/sfx/King Default Attack.mp3")
const SPIN: AudioStream = preload("res://assets/sfx/King Spinning Attack.mp3")
const CHIME: AudioStream = preload("res://assets/sfx/Roulette Wheel Attack Sound.mp3")
const ENTRANCE: AudioStream = preload("res://assets/sfx/Boss entrance sound.mp3")
var play_counts: Dictionary = {}

func _ready() -> void:
	super()
	add_to_group(&"sound_effects")

func play_event(event: StringName) -> void:
	var stream: AudioStream = SWING
	var pitch: float = 1.0
	var volume: float = -6.0
	match event:
		&"chipper_attack": stream = CHIP
		&"crusher_slam": stream = SLAM
		&"crusher_warning":
			stream = ENTRANCE
			volume = -16.0
		&"jump":
			stream = SPIN
			pitch = 1.4
			volume = -14.0
		&"orb", &"heal", &"checkpoint":
			stream = CHIME
			pitch = 1.8 if event == &"orb" else 1.3
			volume = -12.0
		&"hurt": pitch = 0.8
		&"death": stream = SLAM
	play_sfx(stream, volume, pitch)
	play_counts[event] = int(play_counts.get(event, 0)) + 1
