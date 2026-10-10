extends Control

@onready var StateLabel = get_node("%State")
@onready var DashedLabel = get_node("%Dashed")
@onready var HealthLabel = get_node("%Health")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_player_character__dashed(dashed):
	DashedLabel.set_text(dashed)


func _on_player_character__state(state_name):
	StateLabel.set_text(state_name)


func _on_player_character__hit_points(hit_points):
	HealthLabel.set_text(str(hit_points))
