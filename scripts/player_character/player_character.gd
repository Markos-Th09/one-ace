extends CharacterBody2D

@onready var Sprite = $Sprite2D
@onready var CoyoteTimer = get_node("%CoyoteTimer")
@onready var JumpBuffer = get_node("%JumpBufferTimer")
@onready var StateMachine = $States
@onready var WallCast = get_node("%WallRayCast")
@onready var DashTimer = get_node("%DashTimer")
@onready var ClimbTimer = get_node("%ClimbTimer")
@onready var WallJumpTimer = get_node("%WallCheckTimer")
@onready var InvulnerabilityTimer = get_node("%InvulnerabilityTimer")

@export var TimeToJumpApex: float = .5
@export var JumpHeight: float = 64.0
@export var JumpDistance: float = 96.0
@export var MaxDash: int = 1
@export var Acceleration = 1000
@export var WallSlideSpeed: int = 2


var OnFloor: bool = false
var JumpPressed: bool = false
var WallCastDir: Vector2 = Vector2(12,0)
var Dashed: int = 0
var DashReady:bool = true
var CanClimb: bool = false
var Climbing: bool = false
var ClimbFlash

var Life = 3
var Invulnerability: bool = false

signal _State
signal _Dashed
signal _hit_points
signal _dead

func _ready():
	WallCastDir = WallCast.get_target_position()
	ClimbFlash = Sprite.get_material()
	
	for c in StateMachine.get_children():
		if c.has_method("SetVariables"):
			c.SetVariables([TimeToJumpApex,JumpHeight,JumpDistance,MaxDash,Acceleration,WallSlideSpeed])
			if c.has_method("GetSpeed"):
				c.GetSpeed()
	WallJumpTimer.set_wait_time(TimeToJumpApex)
	
func _process(delta):
	if !is_on_floor():
		if CoyoteTimer.is_stopped():
			CoyoteTimer.start()
	else:
		OnFloor = true
		CanClimb = true
		if JumpPressed == true:
			StateMachine._change_state("jump")
		if DashReady == true:
			Dashed = 0
		ClimbTimer.stop()
		
	if Input.is_action_just_pressed("jump"):
		if OnFloor == false && JumpBuffer.is_stopped():
			JumpPressed = true
			JumpBuffer.start()
			
	emit_signal("_State", StateMachine.current_state.name)
	emit_signal("_Dashed", str(Dashed))
	
	SetClimbFlash(ClimbTimer.time_left)
	
	if Invulnerability:
		SetDamageFlash(InvulnerabilityTimer.time_left)
		
func SetDamageFlash(_time):
	var Amt : float = 0.0
	var TotalTime = InvulnerabilityTimer.wait_time
	
	Amt = (1-(_time/TotalTime))*100

	if fmod(Amt,10)>2.0:
		Amt = 0
	else:
		Amt = 1
	ClimbFlash.set_shader_parameter("Hit_Amount", Amt)
	
func SetClimbFlash(time):
	var Amt
	var TotalTime = ClimbTimer.wait_time
	Amt = 1-(time/TotalTime)

	if !Climbing:
		Amt = 0
		
	ClimbFlash.set_shader_parameter("Climb_Amount", Amt)

func move(_velocity):
	velocity = _velocity
	move_and_slide()

func Flip_Direction(Direction):
	var Face = signf(Direction)
	if Face == 1:
		Sprite.flip_h = false
	elif Face == -1:
		Sprite.flip_h = true

func IsOnGround():
	return OnFloor
	
func _on_coyote_timer_timeout():
	OnFloor = false

func _on_jump_buffer_timer_timeout():
	JumpPressed = false

func _on_dash_initiated_dash():
	if Dashed == MaxDash:
		StateMachine.current_state.Return(true)
	else:
		Dashed += 1
		StateMachine.current_state.InitiateDash()
		DashTimer.start()
		DashReady = false

func _on_dash_timer_timeout():
	DashReady = true

func _on_climb_update_offset(Offset):
	Sprite.set_offset(Vector2(Offset,0))

func EndClimbing():
	CanClimb = false
	Climbing = false
	if StateMachine.current_state.has_method("ClimbTimeout"):
		StateMachine.current_state.ClimbTimeout()

func _on_climb_climbing(state):
	

	if state:
		if CanClimb:
			Climbing = true
			if ClimbTimer.is_stopped():
				ClimbTimer.start()
			if ClimbTimer.is_paused():
				ClimbTimer.set_paused(false)
		else:
			EndClimbing()
	else:
		Climbing = false
		ClimbTimer.set_paused(true)

func CheckLife(_life):
	if _life<=0:
		StateMachine._change_state("die")
		emit_signal("_dead")
		
func TakeDamage(_damage):
	if Invulnerability == false:
		StateMachine._change_state("damage")
		Life = Life - _damage
		emit_signal("_hit_points", Life)
		CheckLife(Life)
		Invulnerability = true
		if InvulnerabilityTimer.is_stopped():
			InvulnerabilityTimer.start()
		


func _on_invulnerability_timeout():
	Invulnerability = false
	ClimbFlash.set_shader_parameter("Hit_Amount", 0)
