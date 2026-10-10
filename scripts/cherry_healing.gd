extends Area2D
@export var healing_amount: int = 2
var collected: bool = false
var age: float = 0.0
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_try_heal)

func _physics_process(delta: float) -> void:
	age += delta
	sprite.position.y = sin(age * 3.5) * 5.0
	# Retry while overlapping: a full-health player can use it after getting hurt.
	for body: Node2D in get_overlapping_bodies():
		_try_heal(body)

func _try_heal(body: Node2D) -> void:
	if collected or not body.is_in_group(&"player") or not body.has_method("heal"):
		return
	if bool(body.call("heal", healing_amount)):
		collected = true
		queue_free()
