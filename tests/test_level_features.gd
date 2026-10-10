extends "res://tests/test_case.gd"

func _level() -> Node2D:
	var level: Node2D = add_scene("res://scenes/casino_level.tscn") as Node2D
	for enemy: Node in get_tree().get_nodes_in_group(&"enemy"):
		enemy.set_physics_process(false)
	return level

func test_cherries_restore_two_hearts_and_stay_when_full() -> void:
	var level: Node2D = _level()
	var player: CharacterBody2D = level.get_node("Player")
	var cherry: Area2D = level.get_node("Collectibles/Cherry1")
	assert_eq(player.health.max_health, 4)
	cherry._try_heal(player)
	assert_false(cherry.collected, "Full health must not waste the item")
	player.take_damage(3)
	cherry._try_heal(player)
	assert_eq(player.health.current_health, 3)
	assert_true(cherry.collected)
	assert_eq(level.get_node("SoundEffects").play_counts[&"heal"], 1)
	assert_true(player.heal(2))
	assert_eq(player.health.current_health, 4, "Healing caps at four")
	assert_eq(level.get_node("HUD/Panel/Margin/VBox/Health").text, "ACE  ♥♥♥♥")

func test_checkpoint_trigger_respawns_and_preserves_currency() -> void:
	var level: Node2D = _level()
	var player: CharacterBody2D = level.get_node("Player")
	player.set_physics_process(false)
	player.global_position = level.get_node("Checkpoint1").global_position
	player.collect_currency(5)
	await wait_physics_frames(5)
	assert_eq(level.checkpoint_number, 1)
	assert_true(level.get_node("Checkpoint1").activated)
	player.global_position = Vector2(2000, 1500)
	player.health.kill()
	await wait_physics_frames(85)
	assert_true(player.is_alive())
	assert_eq(player.health.current_health, 4)
	assert_between(player.global_position.x, 1240.0, 1255.0)
	assert_true(player.is_on_floor())
	assert_eq(player.currency, 5)
	assert_true(player.health.is_invulnerable(), "Respawn gives time to move")
	assert_false(level.activate_checkpoint(0, Vector2.ZERO), "Progress cannot move backwards")

func test_actual_cherry_overlap_heals_player() -> void:
	var level: Node2D = _level()
	var player: CharacterBody2D = level.get_node("Player")
	var cherry: Area2D = level.get_node("Collectibles/Cherry1")
	player.set_physics_process(false)
	player.global_position = cherry.global_position
	await wait_physics_frames(4)
	assert_false(cherry.collected)
	player.take_damage(2)
	await wait_physics_frames(4)
	assert_eq(player.health.current_health, 4, "Real Area2D overlap heals without a direct pickup call")
	assert_false(is_instance_valid(cherry), "Consumed healing item is removed")

func test_crusher_warns_slams_and_recovers_with_sound() -> void:
	var level: Node2D = _level()
	var player: CharacterBody2D = level.get_node("Player")
	var crusher: CharacterBody2D = level.get_node("Enemies/Crusher1")
	player.set_physics_process(false)
	player.global_position = Vector2(700, 650)
	crusher.home = Vector2(700, 430)
	crusher.global_position = crusher.home
	crusher.set_physics_process(true)
	await wait_physics_frames(20)
	assert_eq(crusher.phase, crusher.Phase.WARNING)
	assert_eq(player.health.current_health, 4)
	await wait_physics_frames(55)
	assert_eq(player.health.current_health, 3)
	assert_eq(crusher.phase, crusher.Phase.RECOVER)
	assert_eq(level.get_node("SoundEffects").play_counts[&"crusher_slam"], 1)
	await wait_physics_frames(130)
	assert_lt(crusher.global_position.y, 550.0, "Crusher returns to flight")

func test_crusher_warning_can_be_dodged_and_enemy_can_die() -> void:
	var level: Node2D = _level()
	var player: CharacterBody2D = level.get_node("Player")
	var crusher: CharacterBody2D = level.get_node("Enemies/Crusher1")
	player.set_physics_process(false)
	player.global_position = Vector2(700, 650)
	crusher.home = Vector2(700, 430)
	crusher.global_position = crusher.home
	crusher.set_physics_process(true)
	await wait_physics_frames(20)
	player.global_position.x = 400.0
	await wait_physics_frames(70)
	assert_eq(player.health.current_health, 4)
	assert_true(crusher.take_damage(3))
	assert_eq(crusher.phase, crusher.Phase.DEAD)
	assert_eq(crusher.collision_layer, 0)

func test_all_supplied_sound_events_have_playable_streams() -> void:
	var level: Node2D = _level()
	var sounds: Node = level.get_node("SoundEffects")
	for event: StringName in [&"attack", &"jump", &"orb", &"heal", &"checkpoint", &"chipper_attack", &"crusher_warning", &"crusher_slam", &"hurt", &"death"]:
		sounds.play_event(event)
		assert_eq(sounds.play_counts[event], 1)
	var sounding: int = 0
	for voice: AudioStreamPlayer in sounds._sfx_players:
		assert_not_null(voice.stream)
		assert_gt(voice.stream.get_length(), 0.0)
		if voice.playing:
			sounding += 1
	assert_gt(sounding, 0)
