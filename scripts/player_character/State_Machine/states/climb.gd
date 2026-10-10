extends Motion

signal UpdateOffset
signal Climbing

var Offset = 4
var ClimbUp:bool = false
var s

func enter():
	s = Speed/2
	ClimbUp = false
	Velocity = Vector2.ZERO
	AnimState.travel("climb")
	Offset = 4*sign(ClimbUpCast.get_target_position().x)
	emit_signal("UpdateOffset", Offset)
	emit_signal("Climbing", true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func handle_input(_event):
	if Input.is_action_just_released("sprint"):
		Offset = 0
		emit_signal("UpdateOffset", Offset)
		emit_signal("Climbing", false)
		emit_signal("finished","wall_slide")


func update(_delta):
	var Dir = GetInput()
	if !ClimbUp:
		var CheckCollision = GetClimbCollision(Dir)

		if CheckCollision == false:
			Dir = Vector2.ZERO
			
			if owner.is_on_floor():
				Offset = 0
				emit_signal("Climbing", false)
				emit_signal("finished","idle")
				emit_signal("UpdateOffset", Offset)
				
			if !ClimbUpCast.is_colliding():
				ClimbUp = true
		
		Climb(s,Dir,_delta)
		
		AnimTree.set("parameters/climb/blend_position", Dir)
		
	else:
		Dir.x = Offset
		Velocity.y = -150
		Move(Speed,Dir,_delta)
		if !ClimbDownCast.is_colliding():
			Offset = 0
			emit_signal("Climbing", false)
			emit_signal("finished","idle")
			emit_signal("UpdateOffset", Offset)
	
	
func Climb(_speed, _direction, delta):
	Velocity.y = move_toward(Velocity.y, _direction.y*_speed, Acceleration*delta)
	emit_signal("UpdateVelocity", -Velocity)

func GetClimbCollision(_direction):
	if _direction.y == 1:
		var up = ClimbUpCast.is_colliding()
		return up
		
	elif _direction.y == -1:
		var down = ClimbDownCast.is_colliding()
		return down

func ClimbTimeout():
	Offset = 0
	emit_signal("UpdateOffset", Offset)
	emit_signal("Climbing", false)
	emit_signal("finished","fall")
