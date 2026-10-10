extends CharacterBody2D
## Flying slot-machine enemy: hover, telegraph, slam, recover, rise.
const HealthComponent = preload("res://scripts/components/health.gd")
enum Phase { HOVER, WARNING, SLAM, RECOVER, RISE, DEAD }
@export var hover_speed: float = 65.0
@export var slam_speed: float = 700.0
@export var warning_time: float = 0.7
@export var detection_range: float = 230.0
@export var damage: int = 1
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health: HealthComponent = $Health
@onready var hitbox: Area2D = $DamageArea
var phase: Phase = Phase.HOVER
var home: Vector2 = Vector2.ZERO
var phase_time: float = 0.0
var floor_y: float = 0.0
var impact_x: float = 0.0
var age: float = 0.0
var hit_this_slam: bool = false
var patrol_direction: float = 1.0

func _ready() -> void:
	home = global_position
	health.died.connect(_die)
	sprite.play(&"hover")

func _physics_process(delta: float) -> void:
	age += delta
	phase_time = maxf(phase_time - delta, 0.0)
	match phase:
		Phase.HOVER:
			var target: Node2D = _target()
			var direction: float = patrol_direction
			if target != null:
				direction = signf(target.global_position.x - global_position.x)
			else:
				if absf(global_position.x - home.x) > 90.0:
					patrol_direction = -1.0 if global_position.x > home.x else 1.0
			velocity = Vector2(direction * hover_speed, (home.y + sin(age * 2.0) * 12.0 - global_position.y) * 4.0)
			move_and_slide()
			if target != null and absf(target.global_position.x - global_position.x) < 65.0:
				_begin_warning()
		Phase.WARNING:
			velocity = Vector2.ZERO
			sprite.modulate = Color(1.0, 0.6 + sin(age * 20.0) * 0.2, 0.45)
			if phase_time == 0.0:
				phase = Phase.SLAM
				sprite.modulate = Color.WHITE
				sprite.play(&"drop")
		Phase.SLAM:
			velocity = Vector2(0.0, slam_speed)
			move_and_slide()
			_damage_overlaps()
			if is_on_floor():
				phase = Phase.RECOVER
				phase_time = 0.8
				velocity = Vector2.ZERO
				sprite.play(&"impact")
				get_tree().call_group(&"sound_effects", &"play_event", &"crusher_slam")
			elif global_position.y > floor_y + 100.0:
				phase = Phase.RISE
		Phase.RECOVER:
			if phase_time > 0.55:
				_damage_overlaps()
			if phase_time == 0.0:
				phase = Phase.RISE
				sprite.play(&"rise")
		Phase.RISE:
			velocity = Vector2(0.0, -180.0)
			move_and_slide()
			if global_position.y <= home.y:
				global_position.y = home.y
				phase = Phase.HOVER
				sprite.play(&"hover")
		Phase.DEAD:
			if phase_time == 0.0:
				queue_free()
	queue_redraw()
	var texture: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	sprite.position.y = 50.0 - float(texture.get_height()) * 0.25

func _target() -> Node2D:
	for candidate: Node in get_tree().get_nodes_in_group(&"player"):
		var player: Node2D = candidate as Node2D
		if player != null and bool(player.call("is_alive")) and absf(player.global_position.x - global_position.x) < detection_range and player.global_position.y > global_position.y:
			return player
	return null

func _begin_warning() -> void:
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, 800), 1)
	var result: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return
	var floor_position: Vector2 = result["position"]
	floor_y = floor_position.y
	impact_x = global_position.x
	phase = Phase.WARNING
	phase_time = warning_time
	hit_this_slam = false
	get_tree().call_group(&"sound_effects", &"play_event", &"crusher_warning")

func _damage_overlaps() -> void:
	if hit_this_slam:
		return
	for body: Node2D in hitbox.get_overlapping_bodies():
		if body.is_in_group(&"player") and body.has_method("take_damage"):
			body.call("take_damage", damage, global_position)
			hit_this_slam = true
			return

func _draw() -> void:
	if phase == Phase.WARNING or phase == Phase.SLAM:
		var marker: Vector2 = Vector2(impact_x, floor_y) - global_position
		draw_rect(Rect2(marker + Vector2(-68, -5), Vector2(136, 7)), Color(1.0, 0.15, 0.08, 0.85))
		draw_circle(marker + Vector2(0, -15), 8.0, Color("ffbe45"))

func take_damage(amount: int, _source_position: Vector2 = Vector2.ZERO) -> bool:
	return health.apply_damage(amount)

func _die() -> void:
	phase = Phase.DEAD
	phase_time = 0.35
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	sprite.modulate = Color(0.5, 0.5, 0.5, 0.6)
	sprite.play(&"impact")
	get_tree().call_group(&"sound_effects", &"play_event", &"crusher_slam")

func reset_to_spawn() -> void:
	global_position = home
	velocity = Vector2.ZERO
	phase = Phase.HOVER
	phase_time = 0.0
	sprite.modulate = Color.WHITE
	sprite.play(&"hover")
	health.reset()
