class_name PlayerInput extends Node

@onready var joystick: VirtualJoystickPlus
var _dir: Vector2 = Vector2.ZERO

func _ready() -> void:
	if not is_multiplayer_authority(): return
	
	joystick = get_tree().root.get_node("Main/SceneContainer/Game/CanvasLayer/Root/UIControlPlayer/PlayerJoystick")

func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority() or not joystick: return

	_dir = joystick.get_value()

func get_dir() -> Vector2:
	return _dir
