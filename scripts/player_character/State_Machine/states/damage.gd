extends State

@onready var AnimTree = owner.get_node("%AnimationTree")
@onready var AnimPlayer = owner.get_node("%AnimationPlayer")
@onready var AnimState = AnimTree.get("parameters/playback")

func enter():
	AnimState.travel("hurt")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func handle_input(_event):
	return

func update(_delta):
	return

func Damaged():
	pass
	
func EndDamage():
	emit_signal("finished", "idle")
