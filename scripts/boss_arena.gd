extends Node2D
@onready var boss: CharacterBody2D = $BlackChipper
@onready var left_gate: CollisionShape2D = $LeftGate/CollisionShape2D
@onready var right_gate: CollisionShape2D = $RightGate/CollisionShape2D
@onready var bar: ProgressBar = $HUD/BossHealth
@onready var label: Label = $HUD/BossLabel
var active: bool = false
var cleared: bool = false

func _ready() -> void:
	boss.defeated.connect(_on_defeated)
	boss.health_updated.connect(_update_health)
	bar.hide()
	label.hide()

func _process(_delta: float) -> void:
	var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	if not active and not cleared and player != null and player.is_alive() and player.global_position.x > 3420.0 and player.global_position.y < 600.0:
		active = true
		_set_gates(true)
		bar.show()
		label.show()
		boss.engage()

func reset_arena() -> void:
	if cleared:
		return
	active = false
	_set_gates(false)
	bar.hide()
	label.hide()

func _set_gates(locked: bool) -> void:
	left_gate.set_deferred("disabled", not locked)
	right_gate.set_deferred("disabled", not locked)
	queue_redraw()

func _on_defeated() -> void:
	cleared = true
	active = false
	_set_gates(false)
	bar.hide()
	label.text = "BLACK CHIPPER DEFEATED — CASH OUT >>"
	get_tree().call_group(&"sound_effects", &"play_event", &"checkpoint")

func _update_health(current: int, maximum: int) -> void:
	bar.max_value = maximum
	bar.value = current
	label.text = "BLACK CHIPPER  %d / %d   •   JUMP OVER SPECIAL ATTACKS" % [current, maximum]

func _draw() -> void:
	for x: float in [3330.0, 4598.0]:
		draw_rect(Rect2(x - 8, 330, 16, 246), Color(0.85, 0.58, 0.18, 0.7))
		if active:
			for y: int in range(330, 576, 24):
				draw_line(Vector2(x - 8, y), Vector2(x + 8, y + 12), Color(1, 0.85, 0.2), 4)
