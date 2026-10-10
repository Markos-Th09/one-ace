extends Node2D
@onready var player: CharacterBody2D = $Player
@onready var health_label: Label = $HUD/Panel/Margin/VBox/Health
@onready var message: Label = $HUD/Message
@onready var currency_label: Label = $HUD/Panel/Margin/VBox/Currency
@onready var checkpoint_label: Label = $HUD/Panel/Margin/VBox/Checkpoint
var finished: bool = false
var checkpoint_number: int = 0
var spawn_position: Vector2 = Vector2(128, 700)
var respawn_time: float = -1.0

func _ready() -> void:
	add_to_group(&"checkpoint_level")
	spawn_position = player.global_position
	player.health_changed.connect(_update_health)
	player.died.connect(_on_player_died)
	player.currency_changed.connect(_update_currency)
	_update_health(player.health.current_health)
	_update_currency(0)
	checkpoint_label.text = "CHECKPOINT: START"

func _process(delta: float) -> void:
	if Input.is_action_just_pressed(&"restart"):
		if finished:
			get_tree().reload_current_scene()
		else:
			respawn_at_checkpoint()
	if respawn_time >= 0.0:
		respawn_time -= delta
		if respawn_time <= 0.0:
			respawn_at_checkpoint()
	if not finished and $BossArena.cleared and player.is_alive() and player.global_position.x > 4510.0 and player.global_position.y < 600.0:
		finished = true
		message.text = "HOUSE BEATEN!\nPress R to play again"
		player.set_physics_process(false)
		for enemy: Node in get_tree().get_nodes_in_group(&"enemy"):
			enemy.set_physics_process(false)
	if player.is_alive() and player.global_position.y > 1200.0:
		player.health.kill()

func activate_checkpoint(number: int, location: Vector2) -> bool:
	if number <= checkpoint_number or not player.is_alive():
		return false
	checkpoint_number = number
	spawn_position = location
	checkpoint_label.text = "CHECKPOINT: %d SAVED" % number
	get_tree().call_group(&"sound_effects", &"play_event", &"checkpoint")
	return true

func respawn_at_checkpoint() -> void:
	if finished:
		return
	respawn_time = -1.0
	message.text = ""
	$BossArena.reset_arena()
	for enemy: Node in get_tree().get_nodes_in_group(&"enemy"):
		if enemy.has_method("reset_to_spawn") and enemy.health.is_alive():
			enemy.reset_to_spawn()
	player.respawn(spawn_position)

func _update_health(current: int) -> void:
	health_label.text = "ACE  " + "♥".repeat(current) + "♡".repeat(player.health.max_health - current)

func _update_currency(current: int) -> void:
	currency_label.text = "ORBS: %d" % current

func _on_player_died() -> void:
	message.text = "THE HOUSE WINS\nReturning to checkpoint..."
	respawn_time = 1.0
