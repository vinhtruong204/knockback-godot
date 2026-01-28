class_name State
extends Node

var state_machine: StateMachine

func enter(): 
	print(name)

func exit(): pass
func update(_delta: float): pass
func physics_update(_delta: float): pass
