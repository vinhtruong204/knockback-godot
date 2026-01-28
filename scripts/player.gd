extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
@onready var animation = $AnimatedSprite2D
@export var health = 50:
	set(new_val):
		health = new_val
	get:
		return health

var input_dir: Vector2

func _enter_tree() -> void:
	if is_multiplayer_authority():
		health = int(self.name)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	if Input.is_action_pressed('ui_page_down'):
		health = 30
	
	input_dir = Vector2(
		Input.get_axis("ui_left", "ui_right"),
		0
	)

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		animation.play("run")
	else:
		animation.play("idle")
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
