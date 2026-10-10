extends CharacterBody2D
## The house champion alternates a locked rapier dash and a jumpable blade sweep.
signal defeated
signal health_updated(current: int, maximum: int)
const HealthComponent = preload("res://scripts/components/health.gd")
enum Phase { WAIT, APPROACH, WINDUP, DASH, SPIN, RECOVER, DEAD }
@onready var health: HealthComponent = $Health
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var phase: Phase = Phase.WAIT
var timer: float = 0.0
var direction: float = -1.0
var next_spin: bool = false
var attack_is_spin: bool = false
var hit_this_attack: bool = false
var home: Vector2 = Vector2.ZERO
var age: float = 0.0

func _ready() -> void:
	home = global_position
	health.damaged.connect(_on_damaged)
	health.died.connect(_die)
	sprite.play(&"idle")

func engage() -> void:
	if phase != Phase.WAIT:
		return
	phase = Phase.APPROACH
	timer = 1.0
	get_tree().call_group(&"sound_effects", &"play_event", &"boss_entrance")
	health_updated.emit(health.current_health, health.max_health)

func _physics_process(delta: float) -> void:
	age += delta
	timer = maxf(timer - delta, 0.0)
	velocity.y += 850.0 * delta
	var target: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	if phase == Phase.DEAD:
		velocity.x = 0.0
		move_and_slide()
		return
	match phase:
		Phase.WAIT:
			velocity.x = 0.0
		Phase.APPROACH:
			if target != null:
				direction = -1.0 if target.global_position.x < global_position.x else 1.0
				velocity.x = direction * 75.0 if absf(target.global_position.x - global_position.x) > 105.0 else 0.0
				sprite.play(&"walk" if velocity.x != 0.0 else &"idle")
				if timer == 0.0 and absf(target.global_position.x - global_position.x) < 220.0:
					_begin_attack()
		Phase.WINDUP:
			velocity.x = 0.0
			sprite.modulate = Color(1.0, 0.7 + sin(age * 22.0) * 0.2, 0.3)
			if timer == 0.0:
				sprite.modulate = Color.WHITE
				phase = Phase.SPIN if attack_is_spin else Phase.DASH
				timer = 0.65 if attack_is_spin else 0.48
				sprite.play(&"spin" if attack_is_spin else &"lunge")
				get_tree().call_group(&"sound_effects", &"play_event", &"boss_spin" if attack_is_spin else &"boss_dash")
		Phase.DASH, Phase.SPIN:
			velocity.x = direction * (45.0 if phase == Phase.SPIN else 380.0)
			_damage_player(target)
			if timer == 0.0:
				phase = Phase.RECOVER
				timer = 1.1
				sprite.play(&"idle")
		Phase.RECOVER:
			velocity.x = 0.0
			if timer == 0.0:
				phase = Phase.APPROACH
				timer = 0.65
	sprite.flip_h = direction > 0.0
	move_and_slide()
	global_position.x = clampf(global_position.x, 3410.0, 4540.0)
	queue_redraw()

func _begin_attack() -> void:
	attack_is_spin = next_spin
	next_spin = not next_spin
	hit_this_attack = false
	phase = Phase.WINDUP
	timer = (0.85 if attack_is_spin else 0.65) * (0.8 if health.current_health <= 5 else 1.0)
	sprite.play(&"spin" if attack_is_spin else &"lunge")
	sprite.pause()
	sprite.frame = 0

func _damage_player(target: Node2D) -> void:
	if target == null or hit_this_attack or not target.is_alive():
		return
	var offset: Vector2 = target.global_position - global_position
	# Both attacks stay close to the floor; jumping clears their hit region.
	var in_reach: bool = absf(offset.x) < 145.0 if phase == Phase.SPIN else offset.x * direction > -35.0 and offset.x * direction < 115.0
	if in_reach and offset.y > -55.0 and offset.y < 80.0:
		hit_this_attack = bool(target.take_damage(1, global_position))

func take_damage(amount: int, _source_position: Vector2 = Vector2.ZERO) -> bool:
	if phase == Phase.WAIT or phase == Phase.DEAD:
		return false
	return health.apply_damage(amount)

func _on_damaged(_amount: int, current: int) -> void:
	health_updated.emit(current, health.max_health)
	get_tree().call_group(&"sound_effects", &"play_event", &"hurt")

func _die() -> void:
	phase = Phase.DEAD
	velocity.x = 0.0
	sprite.modulate = Color.WHITE
	sprite.play(&"death")
	queue_redraw()
	defeated.emit()

func reset_to_spawn() -> void:
	global_position = home
	velocity = Vector2.ZERO
	health.reset()
	phase = Phase.WAIT
	next_spin = false
	sprite.modulate = Color.WHITE
	sprite.play(&"idle")
	queue_redraw()

func _draw() -> void:
	if phase == Phase.WINDUP:
		if attack_is_spin:
			draw_rect(Rect2(-145, 18, 290, 40), Color(1, 0.35, 0.12, 0.28))
			draw_arc(Vector2(0, 45), 145, PI, TAU, 24, Color(1, 0.75, 0.2), 3)
		else:
			draw_line(Vector2.ZERO, Vector2(direction * 190, 0), Color(1, 0.25, 0.15), 5)
	if phase == Phase.SPIN:
		draw_arc(Vector2(0, 35), 135, age * 20, age * 20 + PI * 1.5, 24, Color(1, 0.8, 0.25, 0.85), 6)
