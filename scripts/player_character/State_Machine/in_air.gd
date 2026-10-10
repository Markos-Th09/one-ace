extends Motion

class_name InAir
# Called when the node enters the scene tree for the first time.
func handle_input(_event):
	if Input.is_action_just_pressed("dash"):
		emit_signal("finished", "dash")

func GroundCheck():
	if owner.is_on_floor():
		Dashed = 0
		if Input.is_action_pressed("sprint"):
			emit_signal("finished", "walk")
		else:	
			emit_signal("finished", "run")

func CheckWallCast():
	if WallCast.is_colliding():
		emit_signal("finished","wall_slide")
