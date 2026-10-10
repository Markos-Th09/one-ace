extends Area2D

@export var Damage = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if has_overlapping_bodies():
		_on_body_entered(get_overlapping_bodies()[0])

func _on_body_entered(body):
	if body.has_method("TakeDamage"):
		body.TakeDamage(Damage)
