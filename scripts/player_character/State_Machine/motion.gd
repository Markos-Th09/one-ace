extends State

class_name Motion

var Direction: Vector2 = Vector2.ZERO
var Velocity: Vector2 = Vector2.ZERO
var WallRayCastDir: Vector2 = Vector2(12,0)

var Dashed = 0
var GRAVITY = 0

var Speed: float
var JumpVelocity: float

var TimeToJumpApex: float = 0
var JumpHeight: float = 0
var JumpDistance: float = 0
var MaxDash: int = 1
var Acceleration = 1000
var WallSlideSpeed: int = 3

@onready var AnimTree = owner.get_node("%AnimationTree")
@onready var AnimPlayer = owner.get_node("%AnimationPlayer")
@onready var AnimState = AnimTree.get("parameters/playback")
@onready var WallCast = owner.get_node("%WallRayCast")
@onready var ClimbUpCast = owner.get_node("%ClimbCastUp")
@onready var ClimbDownCast = owner.get_node("%ClimbCastDown")
@onready var StateMachine = get_parent()

signal UpdateVelocity(Velocity)
signal direction(Direction)

func _ready():
	WallRayCastDir = WallCast.get_target_position()


func SetVariables(variable):
	TimeToJumpApex = variable[0]
	JumpHeight = variable[1]
	JumpDistance = variable[2]
	MaxDash = variable[3]
	Acceleration = variable[4]
	WallSlideSpeed = variable[5]

func GetSpeed():
	GRAVITY = (2 * JumpHeight)/ pow(TimeToJumpApex,2)
	JumpVelocity = -(GRAVITY*TimeToJumpApex)
	Speed = JumpDistance/(2*TimeToJumpApex)

func GetInput()->Vector2:
	Direction.x = Input.get_action_strength("ui_right")-Input.get_action_strength("ui_left")
	Direction.y = Input.get_action_strength("ui_up")-Input.get_action_strength("ui_down")
	emit_signal("direction", Direction.x)
	return Direction

func UpdateWallRayCast(dir):
	var WallDir = WallRayCastDir*dir
	WallCast.set_target_position(WallDir)
	ClimbUpCast.set_target_position(WallDir)
	ClimbDownCast.set_target_position(WallDir)

func Move(_speed, _direction, delta):
	Velocity.x = move_toward(Velocity.x, _direction.x*_speed, Acceleration*delta)
	emit_signal("UpdateVelocity", Velocity)
	
func Gravity(delta):
	if not owner.is_on_floor():
		Velocity.y += GRAVITY * delta
	else:
		Velocity.y = 0

func WallSlide(delta):
	if not owner.is_on_floor():
		Velocity.y = GRAVITY*WallSlideSpeed * delta
	else:
		Velocity.y = 0
