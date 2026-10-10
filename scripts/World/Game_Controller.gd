extends Node2D

@onready var GameOverlay = get_node("%Game_Over")
@onready var InforOverlay = get_node("%Info_Layer")

var GameOver: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	
	##Incredibly basic Game Over Loop Replace with whatever you need##
	if GameOver == true:
		if Input.is_anything_pressed():
			await get_tree().create_timer(2).timeout
			var _scene = get_tree().reload_current_scene()

func _on_player_character__dead():
	InforOverlay.hide()
	GameOverlay.show()
	GameOver = true
