extends State
@export var player: CharacterBody2D

func physics_update(_delta: float):
	if player.input_dir != Vector2.ZERO:
		state_machine.change_state("run")
