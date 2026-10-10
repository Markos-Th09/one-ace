extends InAir

func Initialize(v,s):
	Velocity = v
	Speed = s

func enter():
	AnimState.travel("jump")
	Velocity.y = JumpVelocity
	
func handle_input(_event):
	if Input.is_action_just_released("jump"):
		CheckRelease()
	return super.handle_input(_event)

func update(_delta):
	if !owner.is_on_floor():
		Gravity(_delta)

	var Dir = GetInput()
	Move(Speed,Dir,_delta)
	
	UpdateWallRayCast(Dir)
	
	GroundCheck()
	
	if Velocity.y >= 0:
		CheckWallCast()
	
func CheckRelease():
	if Velocity.y < -200:
		Velocity.y = Velocity.y/2
		ToFall()

func ToFall():
	emit_signal("finished", "fall")

