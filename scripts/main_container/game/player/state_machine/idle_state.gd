class_name IdleState extends State

@onready var player_input: PlayerInput = $"../../PlayerInput"

func physics_update(_delta: float):
	if player_input and player_input.get_dir() != Vector2.ZERO:
		state_machine.change_state(PlayerState.RUN)
