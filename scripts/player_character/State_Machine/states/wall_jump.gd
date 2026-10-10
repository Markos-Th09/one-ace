extends InAir
var Dir
var StartCheckingWallCast: bool = false
var Inverted: bool = true
var StartingDir

@onready var WallCheckTimer = get_node("%WallCheckTimer")

func Initialize(d):
	Dir = -d
	StartingDir = -d

func enter():
	Inverted = true
	StartCheckingWallCast = false
	WallCheckTimer.stop()
	AnimState.travel("jump")
	Velocity.y = JumpVelocity
	WallCheckTimer.start()
	
func handle_input(_event):
	return super.handle_input(_event)

func update(_delta):
	if !owner.is_on_floor():
		Gravity(_delta)
	if Inverted == false:
		Dir = GetInvertedDIR()
	
	emit_signal("direction", Dir.x)
	UpdateWallRayCast(Dir)
	
	Move(Speed,Dir,_delta)
	
	GroundCheck()
	
	if StartCheckingWallCast:
		CheckWallCast()

func GetInvertedDIR():
	Direction.x = Input.get_action_strength("ui_right")-Input.get_action_strength("ui_left")
	return Direction
	
func ToFall():
	emit_signal("finished", "fall")

func _on_wall_check_timer_timeout():
	if StateMachine.current_state.name == "wall_jump":
		StartCheckingWallCast = true
		Inverted = false
