extends OnGround

var s

# Called when the node enters the scene tree for the first time.
func Initialize(v):
	Velocity = v

func enter():
	s = Speed/2
	AnimState.travel("move")
	AnimTree.set("parameters/move/blend_position", Vector2(-1,0))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func handle_input(_event):
	if Input.is_action_just_released("sprint"):
		emit_signal("finished", "run")
	return super.handle_input(_event)

func update(_delta):
	var Dir = GetInput()
	Gravity(_delta)
	Move(s,Dir,_delta)
	
	
	if Dir.x == 0:
		emit_signal("finished", "idle")
	CheckGround()
