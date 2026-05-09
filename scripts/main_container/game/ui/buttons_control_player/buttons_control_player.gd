class_name ButtonsControlPlayer extends Control

signal jump_pressed()
signal attack_pressed()
signal bomb_pressed()

@onready var jump_button: TextureButton = $JumpBtn
@onready var attack_button: TextureButton = $AttackBtn
@onready var bomb_button: TextureButton = $BombBtn

var _tracked_touches: Dictionary = {}

func _ready() -> void:
	if not _is_mobile_device():
		jump_button.pressed.connect(_on_jump_btn_pressed)
		attack_button.pressed.connect(_on_attack_btn_pressed)
		bomb_button.pressed.connect(_on_bomb_btn_pressed)


func _input(event: InputEvent) -> void:
	if not _is_mobile_device():
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_handle_touch_pressed(event)
		else:
			_tracked_touches.erase(event.index)


func _handle_touch_pressed(event: InputEventScreenTouch) -> void:
	if _tracked_touches.has(event.index):
		return

	if jump_button.get_global_rect().has_point(event.position):
		_tracked_touches[event.index] = &"jump"
		jump_pressed.emit()
		get_viewport().set_input_as_handled()
		return

	if attack_button.get_global_rect().has_point(event.position):
		_tracked_touches[event.index] = &"attack"
		attack_pressed.emit()
		get_viewport().set_input_as_handled()
		return

	if bomb_button.get_global_rect().has_point(event.position):
		_tracked_touches[event.index] = &"bomb"
		bomb_pressed.emit()
		get_viewport().set_input_as_handled()


func _is_mobile_device() -> bool:
	return OS.get_name().to_lower() in ["android", "ios"]


func _on_jump_btn_pressed() -> void:
	jump_pressed.emit()

func _on_attack_btn_pressed() -> void:
	attack_pressed.emit()

func _on_bomb_btn_pressed() -> void:
	bomb_pressed.emit()
