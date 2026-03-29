class_name PlayerInput extends Node

# Constants
const DROP_DOWN_THRESHOLD: float = 0.8

# Nodes
@onready var joystick: VirtualJoystickPlus
@onready var switch_weapon_handler: SwitchWeaponHandler

# Variables
var _dir: Vector2 = Vector2.ZERO

# Movement signals
signal jump()
signal drop_down()

# Action signals
signal shoot()
signal throw_bomb()

# Switch weapon signals
signal switch_weapon(weapon: SwitchWeaponHandler.WeaponType)

func _ready() -> void:
	if not is_multiplayer_authority(): return
	
	joystick = get_tree().root.get_node("Main/SceneContainer/Game/CanvasLayer/Root/UIControlPlayer/PlayerJoystick")
	switch_weapon_handler = get_tree().root.get_node("Main/SceneContainer/Game/CanvasLayer/Root/UIControlPlayer/SwitchWeaponHandler")

	switch_weapon_handler.weapon_switched.connect(_on_weapon_switched)

func _on_weapon_switched(weapon: SwitchWeaponHandler.WeaponType) -> void:
	switch_weapon.emit(weapon)


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
	
	if Input.is_action_just_pressed("player_throw_bomb"):
		throw_bomb.emit()
	#endregion


func get_dir() -> Vector2:
	return _dir
