extends OnGround

func Initialize(v):
	Velocity = v

# Called when the node enters the scene tree for the first time.
func enter():
	AnimState.travel("idle")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func handle_input(_event):
	return super.handle_input(_event)

func update(_delta):
	var dir = GetInput()
	Gravity(_delta)
	Move(Speed,dir,_delta)
	
	if dir.x != 0:
		if Input.is_action_pressed("sprint"):
			emit_signal("finished", "walk")
		else:
			emit_signal("finished","run")
	CheckGround()
