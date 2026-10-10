extends "res://scripts/enemies/patrol_base.gd"
## Based on the Godot skill's ground-patrol template.
const HealthComponent = preload("res://scripts/components/health.gd")
enum Behavior { PATROL, CHASE, WINDUP, ATTACK, RECOVER, HURT, DEAD }
@export var chase_speed: float = 105.0
@export var detection_range: float = 260.0
@export var attack_range: float = 90.0
@export var attack_damage: int = 1
@export var windup_time: float = 0.4
@export var recovery_time: float = 0.7
@export var patrol_distance: float = 120.0
@onready var health: HealthComponent = $Health
@onready var attack_hitbox: Area2D = $AttackHitbox
var behavior: Behavior = Behavior.PATROL
var _origin_x: float = 0.0
var _phase_time: float = 0.0
var _hit_this_swing: bool = false
var _target: Node2D = null
var spawn_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	_origin_x = global_position.x
	spawn_position = global_position
	health.died.connect(_die)
	_sprite.animation_finished.connect(_on_animation_finished)
	_set_direction(-1)
	_play(&"idle")

func _physics_process(delta: float) -> void:
	if behavior == Behavior.DEAD:
		return
	_phase_time = maxf(_phase_time - delta, 0.0)
	if not is_on_floor():
		velocity.y += _gravity * delta
	if behavior == Behavior.HURT:
		velocity.x = move_toward(velocity.x, 0.0, 450.0 * delta)
		if _phase_time == 0.0:
			behavior = Behavior.PATROL
	elif behavior == Behavior.WINDUP:
		velocity.x = 0.0
		_sprite.modulate = Color(1.0, 0.65, 0.4)
		if _phase_time == 0.0:
			behavior = Behavior.ATTACK
			_phase_time = 0.2
			_hit_this_swing = false
			_play(&"attack")
			get_tree().call_group(&"sound_effects", &"play_event", &"chipper_attack")
	elif behavior == Behavior.ATTACK:
		_try_hit()
		if _phase_time == 0.0:
			behavior = Behavior.RECOVER
			_phase_time = recovery_time
	elif behavior == Behavior.RECOVER:
		velocity.x = 0.0
		if _phase_time == 0.0:
			behavior = Behavior.PATROL
	else:
		_target = _find_target()
		if _target != null:
			behavior = Behavior.CHASE
			_set_direction(1 if _target.global_position.x > global_position.x else -1)
			if absf(_target.global_position.x - global_position.x) <= attack_range and absf(_target.global_position.y - global_position.y) < 70.0:
				behavior = Behavior.WINDUP
				_phase_time = windup_time
				velocity.x = 0.0
				_play(&"idle")
			else:
				velocity.x = float(_direction) * chase_speed if _safe_ahead() else 0.0
				_play(&"walk" if velocity.x != 0.0 else &"idle")
		else:
			behavior = Behavior.PATROL
			if absf(global_position.x - _origin_x) >= patrol_distance:
				_set_direction(1 if global_position.x < _origin_x else -1)
			_patrol_by_rays()
			velocity.x = float(_direction) * speed if _safe_ahead() else 0.0
			_play(&"walk" if velocity.x != 0.0 else &"idle")
	if behavior != Behavior.WINDUP:
		_sprite.modulate = Color.WHITE
	_sprite.flip_h = _direction > 0 if _sprite.animation == &"walk" or _sprite.animation == &"idle" else _direction < 0
	attack_hitbox.position.x = float(_direction) * 60.0
	move_and_slide()

func _safe_ahead() -> bool:
	_edge_ray.force_raycast_update()
	_wall_ray.force_raycast_update()
	return not _wall_ray.is_colliding() and (not is_on_floor() or _edge_ray.is_colliding())

func _find_target() -> Node2D:
	var nearest: Node2D = null
	var nearest_distance: float = detection_range
	for candidate: Node in get_tree().get_nodes_in_group(&"player"):
		var body: Node2D = candidate as Node2D
		if body == null or (body.has_method("is_alive") and not bool(body.call("is_alive"))):
			continue
		var distance: float = global_position.distance_to(body.global_position)
		if distance < nearest_distance:
			var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, body.global_position, 1)
			if get_world_2d().direct_space_state.intersect_ray(query).is_empty():
				nearest = body
				nearest_distance = distance
	return nearest

func _try_hit() -> void:
	if _hit_this_swing:
		return
	for body: Node2D in attack_hitbox.get_overlapping_bodies():
		if not body.is_in_group(&"player"):
			continue
		if body.has_method("take_damage"):
			body.call("take_damage", attack_damage, global_position)
		elif body.has_method("TakeDamage"):
			body.call("TakeDamage", attack_damage)
		else:
			continue
		_hit_this_swing = true
		return

func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO) -> bool:
	if not health.apply_damage(amount):
		return false
	if health.is_alive():
		behavior = Behavior.HURT
		_phase_time = 0.25
		velocity = Vector2(150.0 if global_position.x >= source_position.x else -150.0, -100.0)
		_play(&"idle")
	return true

func _play(clip: StringName) -> void:
	_sprite.play(clip)
	match clip:
		&"idle", &"walk": _sprite.scale = Vector2(0.18, 0.18)
		&"attack": _sprite.scale = Vector2(0.12, 0.12)
		&"death": _sprite.scale = Vector2(0.35, 0.35)

func _die() -> void:
	behavior = Behavior.DEAD
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	attack_hitbox.set_deferred("monitoring", false)
	_sprite.modulate = Color.WHITE
	_play(&"death")

func _on_animation_finished() -> void:
	if behavior == Behavior.DEAD and _sprite.animation == &"death":
		queue_free()

func reset_to_spawn() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	behavior = Behavior.PATROL
	_phase_time = 0.0
	_hit_this_swing = false
	_sprite.modulate = Color.WHITE
	health.reset()
	_play(&"idle")
