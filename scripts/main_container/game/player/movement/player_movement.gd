class_name PlayerMovement extends Node

const SPEED = 300.0
const JUMP_VELOCITY = -600.0

@onready var player_input: PlayerInput = $"../PlayerInput"
@onready var player: CharacterBody2D = $"../"

func _ready() -> void:
	player_input.jump.connect(_on_jump)
	player_input.drop_down.connect(_on_drop_down)

func _on_jump() -> void:
	if not player.is_on_floor(): return

	player.velocity.y = JUMP_VELOCITY

func _on_drop_down() -> void:
	if not player.is_on_floor(): return
	
	drop_down()

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority() or not player_input or not player: return
	
	# Add the gravity.
	if not player.is_on_floor():
		player.velocity += player.get_gravity() * delta

	var dir := player_input.get_dir()

	# Handle movement.
	if dir.length() > 0.0:
		player.velocity.x = dir.x * SPEED
	else:
		player.velocity.x = 0

	player.move_and_slide()

func drop_down():
	var collision = player.get_slide_collision(0)

	if collision:
		var platform = collision.get_collider()

		player.add_collision_exception_with(platform)

		await get_tree().create_timer(0.1).timeout

		player.remove_collision_exception_with(platform)
