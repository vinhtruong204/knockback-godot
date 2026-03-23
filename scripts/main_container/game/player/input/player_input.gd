class_name PlayerInput extends Node

# Constants
const DROP_DOWN_THRESHOLD: float = 0.8

# Nodes
@onready var joystick: VirtualJoystickPlus

# Variables
var _dir: Vector2 = Vector2.ZERO

# Movement signals
signal jump()
signal drop_down()

# Action signals
signal shoot()

func _ready() -> void:
	if not is_multiplayer_authority(): return
	
	joystick = get_tree().root.get_node("Main/SceneContainer/Game/CanvasLayer/Root/UIControlPlayer/PlayerJoystick")

func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority() or not joystick: return

	#region Movement
	_dir = joystick.get_value()

	if Input.is_action_just_pressed("player_jump"):
		jump.emit()
	
	if _dir.y > DROP_DOWN_THRESHOLD:
		drop_down.emit()
	#endregion

	#region Action
	if Input.is_action_just_pressed("player_attack"):
		shoot.emit()
	#endregion


func get_dir() -> Vector2:
	return _dir
