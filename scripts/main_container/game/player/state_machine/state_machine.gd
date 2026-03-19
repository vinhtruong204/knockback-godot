class_name StateMachine extends Node


signal state_changed(new_state_name: String)

var current_state: State
var states: Dictionary[StringName, State] = {}

func _ready() -> void:
	if not is_multiplayer_authority(): return
	
	for child in get_children():
		if child is State:
			child.state_machine = self # set state machine to child
			states.set(child.name.to_lower(), child)
	
	current_state = states[PlayerState.IDLE]
	current_state.enter_state()

func change_state(state_name: StringName) -> void:
	var new_state = states.get(state_name)

	assert(new_state, "State not found:" + state_name)

	if new_state == current_state: return
	
	if current_state:
		current_state.exit_state()
	
	current_state = new_state
	current_state.enter_state()
	
	# emit signal when state changed
	state_changed.emit(state_name)

	print(get_parent().name + " changed state to: " + state_name)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	current_state.physics_update(delta)

func _process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	current_state.process_update(delta)
