class_name PlayerMovement extends Node

const SPEED = 300.0
const JUMP_VELOCITY = -600.0
const KNOCKBACK_DECAY = 200.0
const MAX_SPEED = 500.0

@onready var player_input: PlayerInput = $"../PlayerInput"
@onready var player: CharacterBody2D = $"../"

var knockback_velocity: Vector2 = Vector2.ZERO

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
	if not is_multiplayer_authority() or not player_input or not player:
		return

	# Gravity
	if not player.is_on_floor():
		player.velocity += player.get_gravity() * delta

	# Input movement
	var dir := player_input.get_dir()
	var input_velocity_x := 0.0

	if dir.length() > 0.0:
		input_velocity_x = dir.x * SPEED

	# Blend input + knockback
	var final_velocity_x = input_velocity_x + knockback_velocity.x

	# Clamp
	final_velocity_x = clamp(final_velocity_x, -MAX_SPEED, MAX_SPEED)

	player.velocity.x = final_velocity_x
	player.velocity.y = knockback_velocity.y if knockback_velocity.y != 0 else player.velocity.y

	# Decay knockback
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)

	player.move_and_slide()


func drop_down():
	var collision = player.get_slide_collision(0)

	if collision and not collision.get_collider().get_meta("is_bottom_platform", false):
		var collider = collision.get_collider()

		# Check if collider is valid
		if not collider: return

		player.add_collision_exception_with(collider)

		await get_tree().create_timer(0.1).timeout

		player.remove_collision_exception_with(collider)
