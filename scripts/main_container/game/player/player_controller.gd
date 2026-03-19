class_name PlayerController extends CharacterBody2D

@onready var player_name: Label = $PlayerName

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_name.text = name
	
	if not is_multiplayer_authority():
		player_name.add_theme_color_override("font_color", Color.RED)
	else:
		player_name.add_theme_color_override("font_color", Color.GREEN)
