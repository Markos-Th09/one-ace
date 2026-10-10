extends Area2D
@export var value: int = 1
var collected: bool = false
var origin_y: float = 0.0
var age: float = 0.0

func _ready() -> void:
	origin_y = position.y
	body_entered.connect(_on_body_entered)
	$AnimatedSprite2D.play()

func _process(delta: float) -> void:
	age += delta
	position.y = origin_y + sin(age * 3.0) * 5.0

func _on_body_entered(body: Node2D) -> void:
	if collected or not body.is_in_group(&"player") or not body.has_method("collect_currency"):
		return
	if body.has_method("is_alive") and not bool(body.call("is_alive")):
		return
	collected = true
	body.call("collect_currency", value)
	queue_free()
