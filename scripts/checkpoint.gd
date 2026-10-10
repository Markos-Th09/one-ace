extends Area2D
@export var checkpoint_number: int = 1
var activated: bool = false

func _ready() -> void:
	body_entered.connect(_activate)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-4, -72, 8, 116), Color("c99536"))
	draw_rect(Rect2(4, -70, 62, 38), Color("2bb86e") if activated else Color("653447"))
	draw_rect(Rect2(4, -70, 62, 38), Color("ffe090"), false, 3.0)
	draw_circle(Vector2(32, -50), 9.0, Color("ffe090"))
	draw_rect(Rect2(-16, 42, 32, 8), Color("c99536"))

func _activate(body: Node2D) -> void:
	if activated or not body.is_in_group(&"player"):
		return
	if body.has_method("is_alive") and not bool(body.call("is_alive")):
		return
	var level: Node = get_tree().get_first_node_in_group(&"checkpoint_level")
	if level != null and bool(level.call("activate_checkpoint", checkpoint_number, global_position)):
		activated = true
		queue_redraw()
