extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@export var joystick: VirtualJoystickPlus

func _ready() -> void:
	if is_multiplayer_authority():
		joystick = get_tree().root.get_node("Main/SceneContainer/Game/CanvasLayer/Root/UIControlPlayer/PlayerJoystick")


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	if not joystick: return

	var dir := joystick.get_value()

	if dir.length() > 0.0:
		velocity = dir * SPEED
	else:
		velocity = Vector2.ZERO

	move_and_slide()
