class_name PlatformerController
extends CharacterBody2D
const HealthComponent = preload("res://scripts/components/health.gd")
signal health_changed(current: int)
signal died
signal currency_changed(current: int)
var currency: int = 0
@onready var health: HealthComponent = $Health
var hit_stun: float = 0.0
var attack_cooldown: float = 0.0
var facing_left: bool = false
## An extendable character for platforming games including features like coyote time,
## jump buffering, jump cancelling, sprinting, and wall jumping.
##
## Each mechanic and section
## of logic is broken up into different functions, allowing you to easilly extend this class
## and override the functions you want to change while keeping the remaining logic in place.[br][br]
##
## All default values were found through tests and tweaking to find a solid default state, but they can all
## be adjusted to fit your specific needs

## The four possible character states and the character's current state
enum {IDLE, WALK, JUMP, FALL, WALL_SLIDE}
## The values for the jump direction, default is UP or -1
enum JUMP_DIRECTIONS {UP = -1, DOWN = 1}


## The path to the character's [Sprite2D] node.  If no node path is provided the [param PLAYER_SPRITE] will be set to [param $Sprite2D] if it exists.
@export_node_path("AnimatedSprite2D") var PLAYER_SPRITE_PATH: NodePath
@onready var PLAYER_SPRITE: AnimatedSprite2D = get_node(PLAYER_SPRITE_PATH) if PLAYER_SPRITE_PATH else $AnimatedSprite2D ## The [Sprite2D] of the player character

## The path to the character's [AnimationPlayer] node. If no node path is provided the [param ANIMATION_PLAYER] will be set to [param $AnimationPlayer] if it exists.
@export_node_path("AnimationPlayer") var ANIMATION_PLAYER_PATH: NodePath
@onready var ANIMATION_PLAYER: AnimationPlayer = get_node(ANIMATION_PLAYER_PATH) if ANIMATION_PLAYER_PATH else $AnimationPlayer ## The [AnimationPlayer] of the player character

## Enables/Disables hard movement when using a joystick.  When enabled, slightly moving the joystick
## will only move the character at a percentage of the maximum acceleration and speed instead of the maximum.
@export var JOYSTICK_MOVEMENT := false

## Enable/Disable sprinting
@export var ENABLE_SPRINT := false
## Enable/Disable Wall Jumping
@export var ENABLE_WALL_JUMPING := false

@export_group("Input Map Actions")
# Input Map actions related to each movement direction, jumping, and sprinting.  Set each to their related
# action's name in your Input Mapping or create actions with the default names.
@export var ACTION_UP := "up" ## The input mapping for up
@export var ACTION_DOWN := "down" ## The input mapping for down
@export var ACTION_LEFT := "left" ## The input mapping for left
@export var ACTION_RIGHT := "right" ## The input mapping for right
@export var ACTION_JUMP := "jump" ## The input mapping for jump
@export var ACTION_SPRINT := "sprint" ## The input mapping for sprint

@export_group("Movement Values")
# The following float values are in px/sec when used in movement calculations with 'delta'
## How fast the character gets to the [param MAX_SPEED] value
@export_range(0, 1000, 0.1) var ACCELERATION: float = 500.0
## The overall cap on the character's speed
@export_range(0, 1000, 0.1) var MAX_SPEED: float = 100.0
## Sprint multiplier, multiplies the [param MAX_SPEED] by this value when sprinting
@export_range(0, 10, 0.1) var SPRINT_MULTIPLIER: float = 1.5
## How fast the character's speed goes back to zero when not moving on the ground
@export_range(0, 1000, 0.1) var FRICTION: float = 500.0
## How fast the character's speed goes back to zero when not moving in the air
@export_range(0, 1000, 0.1) var AIR_RESISTENCE: float = 200.0
## The speed of gravity applied to the character
@export_range(0, 1000, 0.1) var GRAVITY: float = 500.0
## The speed of the jump when leaving the ground
@export_range(0, 1000, 0.1) var JUMP_FORCE: float = 300.0
## How fast the character's vertical speed goes back to zero when cancelling a jump
@export_range(0, 1000, 0.1) var JUMP_CANCEL_FORCE: float = 800.0
## The speed the character falls while sliding on a wall. Currently this is only active if wall jumping is active as well.
@export_range(0, 1000, 0.1) var WALL_SLIDE_SPEED: float = 50.0
## How long in seconds after walking off a platform the character can still jump, set this to zero to disable it
@export_range(0, 1, 0.01) var COYOTE_TIMER: float = 0.08
## How long in seconds before landing should the game still accept the jump command, set this to zero to disable it
@export_range(0, 1, 0.01) var JUMP_BUFFER_TIMER: float = 0.1


## The players current state
var state: int = IDLE
var sprite_base_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	sprite_base_scale = PLAYER_SPRITE.scale
	PLAYER_SPRITE.play(&"Idle")
	add_to_group(&"player")
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	health.healed.connect(_on_healed)
## The player is sprinting when [param sprinting] is true
var sprinting := false
## The player can jump when [param can_jump] is true
var can_jump := false
## The player should jump when landing if [param should_jump] is true, this is used for the [param jump_buffering]
var should_jump := false
## The player will execute a wall jump if [param can_wall_jump] is true and the last call of move_and_slide was only colliding with a wall.
var wall_jump := false
## The player is jumping when [param jumping] is true
var jumping := false

## The player can sprint when [param can_sprint] is true
@onready var can_sprint: bool = ENABLE_SPRINT
## The player can wall jump when [param can_wall_jump] is true
@onready var can_wall_jump: bool = ENABLE_WALL_JUMPING


func _physics_process(delta: float) -> void:
	physics_tick(delta)


## Overrideable physics process used by the controller that calls whatever functions should be called
## and any logic that needs to be done on the [param _physics_process] tick
func physics_tick(delta: float) -> void:
	if not health.is_alive():
		return
	hit_stun = maxf(hit_stun - delta, 0.0)
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	if Input.is_action_just_pressed(&"attack") and attack_cooldown == 0.0:
		attack()
	PLAYER_SPRITE.modulate.a = 0.45 if health.is_invulnerable() and sin(Time.get_ticks_msec() * 0.03) > 0.0 else 1.0
	if hit_stun > 0.0:
		handle_gravity(delta)
		move_and_slide()
		return
	var inputs: Dictionary = get_inputs()
	handle_jump(delta, inputs.input_direction, inputs.jump_strength, inputs.jump_pressed, inputs.jump_released)
	handle_sprint(inputs.sprint_strength)
	handle_velocity(delta, inputs.input_direction)

	manage_state()
	manage_animations()

	# We have to handle the gravity after the state
	handle_gravity(delta)

	move_and_slide()

func is_alive() -> bool:
	return health.is_alive()

func collect_currency(amount: int) -> void:
	if amount <= 0 or not health.is_alive():
		return
	currency += amount
	currency_changed.emit(currency)
	get_tree().call_group(&"sound_effects", &"play_event", &"orb")

func heal(amount: int) -> bool:
	if amount <= 0 or not health.is_alive() or health.current_health >= health.max_health:
		return false
	health.heal(amount)
	get_tree().call_group(&"sound_effects", &"play_event", &"heal")
	return true

func respawn(spawn_position: Vector2) -> void:
	health.reset()
	health.grant_immunity(1.5)
	global_position = spawn_position
	velocity = Vector2.ZERO
	hit_stun = 0.0
	attack_cooldown = 0.0
	can_jump = false
	jumping = false
	should_jump = false
	state = IDLE
	PLAYER_SPRITE.modulate = Color.WHITE
	PLAYER_SPRITE.play(&"Idle")
	health_changed.emit(health.current_health)
	set_physics_process(true)
	var camera: Camera2D = find_child("Camera2D", false) as Camera2D
	if camera != null:
		camera.reset_smoothing()

func attack() -> void:
	if not health.is_alive() or attack_cooldown > 0.0:
		return
	attack_cooldown = 0.45
	get_tree().call_group(&"sound_effects", &"play_event", &"attack")
	var facing: float = -1.0 if facing_left else 1.0
	for candidate: Node in get_tree().get_nodes_in_group(&"enemy"):
		var enemy: Node2D = candidate as Node2D
		if enemy == null or not enemy.has_method("take_damage"):
			continue
		var offset_to_enemy: Vector2 = enemy.global_position - global_position
		if absf(offset_to_enemy.x) <= 115.0 and absf(offset_to_enemy.y) <= 65.0 and offset_to_enemy.x * facing >= -15.0:
			var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, enemy.global_position, 1)
			if get_world_2d().direct_space_state.intersect_ray(query).is_empty():
				enemy.call("take_damage", 1, global_position)

func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO) -> bool:
	if not health.apply_damage(amount):
		return false
	if health.is_alive():
		hit_stun = 0.2
		velocity = Vector2(180.0 if global_position.x >= source_position.x else -180.0, -120.0)
	return true

func _on_damaged(_amount: int, current: int) -> void:
	health_changed.emit(current)
	get_tree().call_group(&"sound_effects", &"play_event", &"hurt")

func _on_healed(_amount: int, current: int) -> void:
	health_changed.emit(current)

func _on_died() -> void:
	velocity = Vector2.ZERO
	PLAYER_SPRITE.modulate = Color.WHITE
	PLAYER_SPRITE.scale = sprite_base_scale
	PLAYER_SPRITE.play(&"Death")
	died.emit()
	get_tree().call_group(&"sound_effects", &"play_event", &"death")


## Manages the character's current state based on the current velocity vector
func manage_state() -> void:
	if velocity.y == 0:
		if velocity.x == 0:
			state = IDLE
		else:
			state = WALK
	elif velocity.y < 0:
		state = JUMP
	else:
		if can_wall_jump and is_on_wall_only() and get_input_direction().x != 0:
			state = WALL_SLIDE
		else:
			state = FALL


## Manages the character's animations based on the current state and [param PLAYER_SPRITE] direction based on
## the current horizontal velocity. The expected default animations are [param Idle], [param Walk], [param Jump], and [param Fall]
func manage_animations() -> void:
	if velocity.x > 0:
		facing_left = false
	elif velocity.x < 0:
		facing_left = true
	PLAYER_SPRITE.flip_h = facing_left
	if attack_cooldown > 0.25:
		PLAYER_SPRITE.play(&"Attack")
		# The supplied attack pose points left.
		PLAYER_SPRITE.flip_h = not facing_left
		PLAYER_SPRITE.scale = sprite_base_scale * (320.0 / 900.0)
		return
	match state:
		IDLE:
			PLAYER_SPRITE.play(&"Idle")
		WALK:
			PLAYER_SPRITE.play(&"Walk")
		JUMP:
			PLAYER_SPRITE.play(&"Jump")
		FALL:
			PLAYER_SPRITE.play(&"Fall")
		WALL_SLIDE:
			PLAYER_SPRITE.play(&"Fall")
	# The supplied sheets use different canvas sizes; keep their display height consistent.
	var frame_texture: Texture2D = PLAYER_SPRITE.sprite_frames.get_frame_texture(PLAYER_SPRITE.animation, 0)
	PLAYER_SPRITE.scale = sprite_base_scale * (320.0 / float(frame_texture.get_height()))


## Gets the strength and status of the mapped actions
func get_inputs() -> Dictionary:
	return {
		input_direction = get_input_direction(),
		jump_strength = Input.get_action_strength(ACTION_JUMP),
		jump_pressed = Input.is_action_just_pressed(ACTION_JUMP),
		jump_released = Input.is_action_just_released(ACTION_JUMP),
		sprint_strength = Input.get_action_strength(ACTION_SPRINT) if ENABLE_SPRINT else 0.0,
	}


## Gets the X/Y axis movement direction using the input mappings assigned to the ACTION UP/DOWN/LEFT/RIGHT variables
func get_input_direction() -> Vector2:
	var x_dir: float = Input.get_action_strength(ACTION_RIGHT) - Input.get_action_strength(ACTION_LEFT)
	var y_dir: float = Input.get_action_strength(ACTION_DOWN) - Input.get_action_strength(ACTION_UP)

	return Vector2(x_dir if JOYSTICK_MOVEMENT else sign(x_dir), y_dir if JOYSTICK_MOVEMENT else sign(y_dir))


# ------------------ Movement Logic ---------------------------------
## Takes the delta and applies gravity to the player depending on their state.  This has
## to be handled after the state and animations in the default behaviour to make sure the
## animations are handled correctly.
func handle_gravity(delta: float) -> void:
	velocity.y += GRAVITY * delta

	if can_wall_jump and state == WALL_SLIDE and not jumping:
		velocity.y = clampf(velocity.y, 0.0, WALL_SLIDE_SPEED)

	if not is_on_floor() and can_jump:
		coyote_time()


## Takes delta and the current input direction and either applies the movement or applies friction
func handle_velocity(delta: float, input_direction: Vector2 = Vector2.ZERO) -> void:
	if input_direction.x != 0:
		apply_velocity(delta, input_direction)
	else:
		apply_friction(delta)


## Applies velocity in the current input direction using the [param ACCELERATION], [param MAX_SPEED], and [param SPRINT_MULTIPLIER]
func apply_velocity(delta: float, move_direction: Vector2) -> void:
	var sprint_strength: float = SPRINT_MULTIPLIER if sprinting else 1.0
	velocity.x += move_direction.x * ACCELERATION * delta * (sprint_strength if is_on_floor() else 1.0)
	velocity.x = clamp(velocity.x, -MAX_SPEED * abs(move_direction.x) * sprint_strength, MAX_SPEED * abs(move_direction.x) * sprint_strength)


## Applies friction to the horizontal axis when not moving using the [param FRICTION] and [param AIR_RESISTENCE] values
func apply_friction(delta: float) -> void:
	var fric: float = FRICTION * delta * sign(velocity.x) * -1 if is_on_floor() else AIR_RESISTENCE * delta * sign(velocity.x) * -1
	if abs(velocity.x) <= abs(fric):
		velocity.x = 0
	else:
		velocity.x += fric


## Sets the sprinting variable according to the strength of the sprint input action
func handle_sprint(sprint_strength: float) -> void:
	if sprint_strength != 0 and can_sprint:
		sprinting = true
	else:
		sprinting = false


# ------------------ Jumping Logic ---------------------------------
## Takes delta and the jump action status and strength and handles the jumping logic
func handle_jump(delta: float, move_direction: Vector2, jump_strength: float = 0.0, jump_pressed: bool = false, _jump_released: bool = false) -> void:
	if (jump_pressed or should_jump) and can_jump:
		apply_jump(move_direction)
	elif jump_pressed:
		buffer_jump()
	elif jump_strength == 0 and velocity.y < 0:
		cancel_jump(delta)
	elif can_wall_jump and not is_on_floor() and is_on_wall_only():
		can_jump = true
		wall_jump = true
		jumping = false

	if is_on_floor() and velocity.y >= 0:
		can_jump = true
		wall_jump = false
		jumping = false


## Applies a jump force to the character in the specified direction, defaults to [param JUMP_FORCE] and [param JUMP_DIRECTIONS.UP]
## but can be passed a new force and direction
func apply_jump(move_direction: Vector2, jump_force: float = JUMP_FORCE, jump_direction: int = JUMP_DIRECTIONS.UP) -> void:
	get_tree().call_group(&"sound_effects", &"play_event", &"jump")
	can_jump = false
	should_jump = false
	jumping = true

	if (wall_jump):
		# Jump away from the direction the character is currently facing
		velocity.x += jump_force * -move_direction.x
		wall_jump = false
		velocity.y = 0

	velocity.y += jump_force * jump_direction


## If jump is released before reaching the top of the jump, the jump is cancelled using the [param JUMP_CANCEL_FORCE] and delta
func cancel_jump(delta: float) -> void:
	jumping = false
	velocity.y -= JUMP_CANCEL_FORCE * sign(velocity.y) * delta


## If jump is pressed before hitting the ground, it's buffered using the [param JUMP_BUFFER_TIMER] value and the jump is applied
## if the character lands before the timer ends
func buffer_jump() -> void:
	should_jump = true
	await get_tree().create_timer(JUMP_BUFFER_TIMER).timeout
	should_jump = false


## If the character steps off of a platform, they are given an amount of time in the air to still jump using the [param COYOTE_TIMER] value
func coyote_time() -> void:
	await get_tree().create_timer(COYOTE_TIMER).timeout
	can_jump = false
