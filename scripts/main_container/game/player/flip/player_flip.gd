class_name PlayerFlip extends Node

@onready var player_input: PlayerInput = $"../PlayerInput"
@onready var sprite: Sprite2D = $"../Sprite2D"

func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority() or not player_input: return
	
	var dir := player_input.get_dir()
	
	if dir.x > 0 and not sprite.flip_h:
		sprite.flip_h = true
	elif dir.x < 0 and sprite.flip_h:
		sprite.flip_h = false
