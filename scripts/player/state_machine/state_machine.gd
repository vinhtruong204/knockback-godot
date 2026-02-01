class_name StateMachine extends Node

signal state_change(new_state_name: String)

@export var initial_state: State
var current_state: State
var states: Dictionary[String, State] = {}

func _ready():
	for child in get_children():
		if child is State:
			child.state_machine = self
			states[child.name.to_lower()] = child
			
	if initial_state:
		current_state = initial_state
		initial_state.enter()

func change_state(new_state_name: String):
	var new_state: State = states.get(new_state_name)
	
	assert(new_state, "State not found:" + new_state_name)
	
	if current_state == new_state: return

	if current_state:
		current_state.exit()

	new_state.enter()
	current_state = new_state
	
	# emit state change
	state_change.emit(new_state.name.to_lower())

func _process(delta):
	if current_state:
		current_state.update(delta)

func _physics_process(delta):
	if current_state:
		current_state.physics_update(delta)
