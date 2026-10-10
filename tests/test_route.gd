extends "res://tests/test_case.gd"

func test_entire_platforming_route_reaches_cash_out() -> void:
	var level: Node2D = add_scene("res://scenes/casino_level.tscn") as Node2D
	var player: CharacterBody2D = level.get_node("Player")
	# Combat is exercised by the enemy tests; this proves the terrain route itself.
	for enemy: Node in get_tree().get_nodes_in_group(&"enemy"):
		enemy.set_physics_process(false)
	await wait_physics_frames(35)
	var jumps: Array[float] = [390, 740, 1100, 1670, 1790, 2320, 2500, 2820, 3260]
	var next_jump: int = 0
	var held: bool = false
	var flight_frames: int = 0
	var frame_count: int = 0
	Input.action_press("right")
	while not level.finished and frame_count < 2200:
		if held:
			flight_frames += 1
			if player.is_on_floor() and flight_frames > 8:
				Input.action_release("jump")
				held = false
		elif player.is_on_floor() and next_jump < jumps.size() and player.position.x >= jumps[next_jump]:
			Input.action_press("jump")
			held = true
			flight_frames = 0
			print("ROUTE jump ", next_jump, " at ", player.position)
			next_jump += 1
		await wait_physics_frames(1)
		frame_count += 1
	Input.action_release("right")
	Input.action_release("jump")
	assert_true(level.finished, "Route stopped at %s after %d jumps" % [player.position, next_jump])
	assert_eq(level.checkpoint_number, 2, "The walking route activates both checkpoints")
	assert_gt(player.currency, 5, "Currency is reachable along the route")
	assert_eq(player.health.current_health, 4)
