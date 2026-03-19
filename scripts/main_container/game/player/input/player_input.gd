class_name PlayerInput extends Node

@export var joystick: VirtualJoystickPlus
var _dir: Vector2 = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if is_multiplayer_authority():
		joystick = get_tree().root.get_node("Main/SceneContainer/Game/CanvasLayer/Root/UIControlPlayer/PlayerJoystick")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	if not joystick: return

	_dir = joystick.get_value()

func get_dir() -> Vector2:
	return _dir
