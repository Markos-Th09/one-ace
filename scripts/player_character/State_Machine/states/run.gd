extends OnGround

# Called when the node enters the scene tree for the first time.
func Initialize(v):
	Velocity = v
# Called when the node enters the scene tree for the first time.
func enter():
	AnimState.travel("move")
	AnimTree.set("parameters/move/blend_position", Vector2(1,0))

	GetSpeed()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func handle_input(_event):
	if Input.is_action_just_pressed("sprint"):
		emit_signal("finished","walk")
	return super.handle_input(_event)

func update(_delta):
	var Dir = GetInput()
	#print(Dir)
	Gravity(_delta)
	Move(Speed,Dir,_delta)
	#print(Velocity)

	if Dir.x == 0:
		emit_signal("finished", "idle")
	CheckGround()
