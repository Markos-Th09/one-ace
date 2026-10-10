extends "res://tests/test_case.gd"

func _arena() -> Node2D:
	var level: Node2D = add_scene("res://scenes/casino_level.tscn") as Node2D
	for enemy: Node in get_tree().get_nodes_in_group(&"enemy"):
		enemy.set_physics_process(false)
	return level

func test_boss_blocks_finish_and_player_attack_unlocks_cash_out() -> void:
	var level: Node2D = _arena()
	var player: CharacterBody2D = level.get_node("Player")
	var arena: Node2D = level.get_node("BossArena")
	var boss: CharacterBody2D = arena.boss
	player.set_physics_process(false)
	player.global_position = Vector2(4520, 513)
	await wait_physics_frames(5)
	assert_false(level.finished, "Walking to the exit cannot skip the boss")
	assert_true(arena.active)
	assert_false(arena.left_gate.disabled)
	player.global_position = Vector2(4000, 513)
	player.facing_left = false
	for strike: int in range(10):
		player.attack_cooldown = 0.0
		player.attack()
		await wait_physics_frames(12)
	assert_eq(boss.health.current_health, 0, "Ordinary player attacks can defeat the mini-boss")
	assert_eq(boss.sprite.animation, &"death")
	assert_true(arena.cleared)
	assert_true(arena.left_gate.disabled)
	player.global_position = Vector2(4520, 513)
	await wait_physics_frames(5)
	assert_true(level.finished)

func test_boss_specials_damage_once_and_can_be_jumped() -> void:
	var level: Node2D = _arena()
	var player: CharacterBody2D = level.get_node("Player")
	var boss: CharacterBody2D = level.get_node("BossArena/BlackChipper")
	player.set_physics_process(false)
	player.global_position = Vector2(4000, 513)
	boss.engage()
	boss._begin_attack()
	assert_eq(boss.phase, boss.Phase.WINDUP)
	assert_false(boss.attack_is_spin)
	assert_gt(boss.timer, 0.5)
	boss.phase = boss.Phase.DASH
	boss._damage_player(player)
	boss._damage_player(player)
	assert_eq(player.health.current_health, 3, "A dash deals one heart once")
	await wait_physics_frames(60)
	boss._begin_attack()
	assert_true(boss.attack_is_spin, "Specials alternate")
	boss.phase = boss.Phase.SPIN
	player.global_position.y = 400
	boss._damage_player(player)
	assert_eq(player.health.current_health, 3, "Jump height clears the sweep")
	player.global_position.y = 513
	boss._damage_player(player)
	assert_eq(player.health.current_health, 2)

func test_boss_retry_resets_fight_and_animation_sheet() -> void:
	var level: Node2D = _arena()
	var boss: CharacterBody2D = level.get_node("BossArena/BlackChipper")
	var arena: Node2D = level.get_node("BossArena")
	boss.engage()
	boss.take_damage(3)
	level.respawn_at_checkpoint()
	assert_eq(boss.health.current_health, 10)
	assert_eq(boss.phase, boss.Phase.WAIT)
	assert_false(arena.active)
	for animation: StringName in [&"idle", &"walk", &"lunge", &"spin", &"death"]:
		assert_eq(boss.sprite.sprite_frames.get_frame_count(animation), 4)
	assert_false(boss.sprite.sprite_frames.get_animation_loop(&"death"))

func test_live_boss_cycles_telegraphs_both_specials_and_recovery() -> void:
	var level: Node2D = _arena()
	var player: CharacterBody2D = level.get_node("Player")
	var boss: CharacterBody2D = level.get_node("BossArena/BlackChipper")
	player.set_physics_process(false)
	player.global_position = Vector2(4000, 380)
	boss.engage()
	boss.set_physics_process(true)
	var seen: Dictionary = {}
	for frame: int in range(420):
		seen[boss.phase] = true
		await wait_physics_frames(1)
	assert_true(seen.has(boss.Phase.WINDUP))
	assert_true(seen.has(boss.Phase.DASH))
	assert_true(seen.has(boss.Phase.SPIN))
	assert_true(seen.has(boss.Phase.RECOVER))
	assert_eq(player.health.current_health, 4)
	assert_gt(level.get_node("SoundEffects").play_counts.get(&"boss_dash", 0), 0)
	assert_gt(level.get_node("SoundEffects").play_counts.get(&"boss_spin", 0), 0)
