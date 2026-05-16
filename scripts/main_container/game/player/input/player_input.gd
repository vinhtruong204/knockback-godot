class_name PlayerInput extends Node

# Constants
const DROP_DOWN_THRESHOLD: float = 0.8
const MOVEMENT_DEADZONE: float = 0.12

# Nodes
@onready var joystick: VirtualJoystickPlus
@onready var switch_weapon_handler: SwitchWeaponHandler
@onready var buttons_control_player: ButtonsControlPlayer

# Variables
var _dir: Vector2 = Vector2.ZERO

# Movement signals
signal jump()
signal drop_down()

# Action signals
signal shoot()
signal throw_bomb()
signal throw_bomb_released()

# Switch weapon signals
signal switch_weapon(weapon: SwitchWeaponHandler.WeaponType)

func _ready() -> void:
	if not is_multiplayer_authority(): return
	
	joystick = get_tree().root.get_node("Main/SceneContainer/Game/CanvasLayer/Root/UIControlPlayer/PlayerJoystick")
	switch_weapon_handler = get_tree().root.get_node("Main/SceneContainer/Game/CanvasLayer/Root/UIControlPlayer/SwitchWeaponHandler")
	buttons_control_player = get_tree().root.get_node("Main/SceneContainer/Game/CanvasLayer/Root/UIControlPlayer/ButtonsWrapper")

	switch_weapon_handler.weapon_switched.connect(_on_weapon_switched)
	buttons_control_player.jump_pressed.connect(_on_jump_pressed)
	buttons_control_player.attack_pressed.connect(_on_attack_pressed)
	buttons_control_player.bomb_pressed.connect(_on_bomb_pressed)
	buttons_control_player.bomb_released.connect(_on_bomb_released)

func _on_weapon_switched(weapon: SwitchWeaponHandler.WeaponType) -> void:
	switch_weapon.emit(weapon)


func _on_jump_pressed() -> void:
	jump.emit()


func _on_attack_pressed() -> void:
	shoot.emit()


func _on_bomb_pressed() -> void:
	throw_bomb.emit()


func _on_bomb_released() -> void:
	throw_bomb_released.emit()


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority() or not joystick: return

	#region Movement
	_dir = _apply_movement_deadzone(joystick.get_value())

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
	if Input.is_action_just_released("player_throw_bomb"):
		throw_bomb_released.emit()
	#endregion


func get_dir() -> Vector2:
	return _dir


func has_movement_input() -> bool:
	return _dir.length() >= MOVEMENT_DEADZONE


func _apply_movement_deadzone(value: Vector2) -> Vector2:
	if value.length() < MOVEMENT_DEADZONE:
		return Vector2.ZERO
	return value
