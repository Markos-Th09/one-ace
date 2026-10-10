extends Motion
var Dir

func Initialize(v,d):
	Dir = d
	Velocity = v

func enter():
	AnimState.travel("wall_slide")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func handle_input(_event):
	if Input.is_action_just_pressed("jump"):
		emit_signal("finished", "wall_jump")
	if Input.is_action_just_pressed("sprint"):
		emit_signal("finished", "climb")

func update(_delta):
	Dir = GetInput()
	UpdateWallRayCast(Dir)
	WallSlide(_delta)
	
	Move(Speed,Dir,_delta)
	
	GroundCheck()
	
	WallCastCheck()
	
func GroundCheck():
	if owner.is_on_floor():
		Velocity = Vector2.ZERO
		Dashed = 0
		if Input.is_action_pressed("sprint"):
			emit_signal("finished", "walk")
		else:	
			emit_signal("finished", "run")

func WallCastCheck():
	if !WallCast.is_colliding():
		emit_signal("finished","fall")
