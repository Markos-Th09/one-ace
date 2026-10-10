extends InAir

# Called when the node enters the scene tree for the first time.
func Initialize(v,s,d):
	Velocity = v
	Speed = s
	Dashed = d

func enter():
	AnimState.travel("fall")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func handle_input(_event):
	if Input.is_action_just_pressed("jump"):
		var onfloor = owner.IsOnGround()
		print("Fall on floor: ", onfloor)
		if onfloor:
			emit_signal("finished", "jump")
	return super.handle_input(_event)

func update(_delta):
	var Dir = GetInput()
	
	Gravity(_delta)
	
	Move(Speed,Dir,_delta)
	
	UpdateWallRayCast(Dir)
	
	CheckWallCast()
	
	GroundCheck()


