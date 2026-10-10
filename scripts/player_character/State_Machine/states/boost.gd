extends Motion

var Dir
var old_speed

signal InitiatedDash
@onready var _Sprite2D = owner.get_node("%Sprite2D")

func Initialize(v,s,d):
	Velocity = v
	old_speed= s
	Dashed = d

func enter():
	emit_signal("InitiatedDash")
	
func handle_input(_event):
	if Input.is_action_just_pressed("jump"):
		var onfloor = owner.IsOnGround()
		if onfloor:
			_Sprite2D.set_rotation(0)
			emit_signal("finished", "jump")

func InitiateDash():
	AnimState.travel("dash")
	Velocity = Vector2.ZERO
	Dir = Vector2.ZERO

func update(_delta):
	Move(Speed,Dir,_delta)
	
func StartDash():
	Dir = GetInput()
	var InputDir = Vector2(abs(Dir.x),Dir.y)
	RotateSprite(InputDir)

	Velocity = Vector2(Dir.x,-Dir.y)*-JumpVelocity*1.5
	
	Speed = abs(Velocity.x)

func RotateSprite(_dir):
	
	var Angle = _dir.angle_to(Vector2(1,0))
	
	if _Sprite2D.is_flipped_h():
		_Sprite2D.set_rotation(-Angle)
	else:
		_Sprite2D.set_rotation(Angle)

func Return(HasDashed:bool):
	
	_Sprite2D.set_rotation(0)
	Speed = old_speed
	
	if !HasDashed:
		Velocity.y = 0
		
	if owner.is_on_floor():
		Dashed = 0
		if Input.is_action_pressed("sprint"):
			emit_signal("finished", "walk")
		else:	
			emit_signal("finished", "run")
	else:
		emit_signal("finished", "fall")
