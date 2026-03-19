class_name PlayerMovement extends Node

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@onready var player_input: PlayerInput = $"../PlayerInput"

func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority() or not player_input: return
	
	var dir := player_input.get_dir()

	if dir.length() > 0.0:
		get_parent().velocity = dir * SPEED
	else:
		get_parent().velocity = Vector2.ZERO

	get_parent().move_and_slide()
