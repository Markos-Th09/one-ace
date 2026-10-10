extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	var level: Node = load("res://scenes/casino_level.tscn").instantiate()
	root.add_child(level)
	for frame: int in range(50):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://assets/casino/level-preview.png")
	var player: CharacterBody2D = level.get_node("Player")
	player.set_physics_process(false)
	for enemy: Node in get_nodes_in_group(&"enemy"):
		enemy.set_physics_process(false)
	player.global_position = Vector2(2900, 680)
	player.get_node("Camera2D").reset_smoothing()
	for frame: int in range(60):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://assets/casino/late-level-preview.png")
	player.global_position = Vector2(4000, 523)
	player.get_node("Camera2D").reset_smoothing()
	for frame: int in range(30):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://assets/casino/boss-preview.png")
	level.queue_free()
	await process_frame
	quit()
