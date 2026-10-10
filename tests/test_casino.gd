extends "res://tests/test_case.gd"

func _level() -> Node2D:
	var level: Node2D = add_scene("res://scenes/casino_level.tscn") as Node2D
	for enemy: Node in get_tree().get_nodes_in_group(&"enemy"):
		enemy.set_physics_process(false)
	return level

func test_player_lands_on_tilemap_and_collects_orb_once() -> void:
	var level: Node2D = _level()
	var player: CharacterBody2D = level.get_node("Player")
	await wait_physics_frames(40)
	assert_true(player.is_on_floor(), "TileMapLayer terrain must have working collision")
	var orb: Area2D = level.get_node("Collectibles/Orb1")
	orb._on_body_entered(player)
	orb._on_body_entered(player)
	assert_eq(player.currency, 1, "An orb adds currency only once")
	assert_eq(level.get_node("HUD/Panel/Margin/VBox/Currency").text, "ORBS: 1")

func test_damage_immunity_and_player_death() -> void:
	var level: Node2D = _level()
	var player: CharacterBody2D = level.get_node("Player")
	assert_true(player.take_damage(1, Vector2.ZERO))
	assert_eq(player.health.current_health, 3)
	assert_false(player.take_damage(1, Vector2.ZERO), "Immediate repeat damage is blocked")
	await wait_physics_frames(60)
	assert_true(player.take_damage(3, Vector2.ZERO))
	assert_false(player.is_alive())
	assert_eq(player.PLAYER_SPRITE.animation, &"Death")
	assert_true(level.get_node("HUD/Message").text.contains("HOUSE WINS"))

func test_chipper_attack_hits_after_windup() -> void:
	var level: Node2D = _level()
	var player: CharacterBody2D = level.get_node("Player")
	var enemy: CharacterBody2D = level.get_node("Enemies/Chipper1")
	player.set_physics_process(false)
	player.global_position = enemy.global_position + Vector2(-70, 0)
	enemy.set_physics_process(true)
	await wait_physics_frames(15)
	assert_eq(player.health.current_health, 4, "Windup gives time to dodge")
	await wait_physics_frames(25)
	assert_eq(player.health.current_health, 3, "The active attack deals one damage")
	assert_eq(enemy.behavior, enemy.Behavior.RECOVER)

func test_dodging_windup_avoids_damage() -> void:
	var level: Node2D = _level()
	var player: CharacterBody2D = level.get_node("Player")
	var enemy: CharacterBody2D = level.get_node("Enemies/Chipper1")
	player.set_physics_process(false)
	player.global_position = enemy.global_position + Vector2(-70, 0)
	enemy.set_physics_process(true)
	await wait_physics_frames(12)
	player.global_position.x -= 220.0
	await wait_physics_frames(35)
	assert_eq(player.health.current_health, 4)

func test_player_can_defeat_chipper() -> void:
	var level: Node2D = _level()
	var player: CharacterBody2D = level.get_node("Player")
	var enemy: CharacterBody2D = level.get_node("Enemies/Chipper1")
	player.set_physics_process(false)
	enemy.health.invulnerability_time = 0.0
	player.global_position = enemy.global_position + Vector2(-80, 0)
	for hit: int in range(3):
		player.attack_cooldown = 0.0
		player.attack()
	assert_eq(enemy.health.current_health, 0)
	assert_eq(enemy.behavior, enemy.Behavior.DEAD)
	assert_eq(enemy.collision_layer, 0)
	assert_eq(enemy.get_node("AnimatedSprite2D").animation, &"death")

func test_jump_reaches_first_raised_platform() -> void:
	var level: Node2D = _level()
	var player: CharacterBody2D = level.get_node("Player")
	player.position = Vector2(380, 714)
	await wait_physics_frames(8)
	Input.action_press("right")
	Input.action_press("jump")
	await wait_physics_frames(60)
	Input.action_release("right")
	Input.action_release("jump")
	assert_gt(player.position.x, 448.0)
	assert_lt(player.position.y, 680.0, "The 64-pixel step is reachable")

