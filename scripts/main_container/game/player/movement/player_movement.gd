class_name PlayerMovement extends Node

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@onready var player_input: PlayerInput = $"../PlayerInput"
@onready var player: CharacterBody2D = $"../"

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority() or not player_input or not player: return
	
	# Add the gravity.
	if not player.is_on_floor():
		player.velocity += player.get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("player_jump") and player.is_on_floor():
		player.velocity.y = JUMP_VELOCITY

	var dir := player_input.get_dir()

	if dir.length() > 0.0:
		player.velocity.x = dir.x * SPEED
	else:
		player.velocity.x = 0

	
	player.move_and_slide()
