extends Motion

class_name OnGround

func handle_input(_event):
	if Input.is_action_just_pressed("jump"):
		var onfloor = owner.IsOnGround()
		if onfloor:
			emit_signal("finished", "jump")
			
	if Input.is_action_just_pressed("dash"):
		emit_signal("finished", "dash")


func CheckGround():
	if owner.is_on_floor() == false:
		emit_signal("finished", "fall")
