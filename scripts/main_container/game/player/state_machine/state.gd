@abstract
class_name State extends Node

var state_machine: StateMachine

func enter_state() -> void:
	pass

func exit_state() -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func process_update(_delta: float) -> void:
	pass
