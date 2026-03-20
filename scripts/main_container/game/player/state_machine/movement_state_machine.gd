class_name MovementStateMachine extends Node


signal state_changed(new_state_name: String)

var current_state: StringName
var states: Dictionary = {}

# Player 
@onready var player: CharacterBody2D = $'..'
@onready var player_input: PlayerInput = player.get_node("PlayerInput")

func _ready() -> void:
	if not is_multiplayer_authority(): return
	
	for child in get_children():
		states.set(StringName(child.name.to_lower()), null)
	
	current_state = MovementState.IDLE

func change_state(state_name: StringName) -> void:
	var is_state_found := states.has(state_name)

	assert(is_state_found, "State not found:" + state_name)
	
	current_state = state_name
	
	# emit signal when state changed
	state_changed.emit(state_name)

	print(get_parent().name + " changed state to: " + state_name)

func resolve_state() -> StringName:
	# if not player.is_on_floor():
		# if player.velocity.y < 0:
		# 	return MovementState.JUMP
		# else:
		# 	return MovementState.FALL
	if player_input.get_dir() != Vector2.ZERO:
		return MovementState.RUN

	return MovementState.IDLE

func _process(_delta: float) -> void:
	if not is_multiplayer_authority(): return

	var next_state := resolve_state()

	if next_state != current_state:
		change_state(next_state)
