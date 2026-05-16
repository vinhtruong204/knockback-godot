class_name ButtonsControlPlayer extends Control

signal jump_pressed()
signal attack_pressed()
signal bomb_pressed()
signal bomb_released()
signal c4_pressed()
signal c4_released()

const C4_BUTTON_TEXTURE: Texture2D = preload("res://assets/game/search_destroy/objective_bomb_icon.png")

@onready var jump_button: TextureButton = $JumpBtn
@onready var attack_button: TextureButton = $AttackBtn
@onready var bomb_button: TextureButton = $BombBtn

var c4_button: TextureButton
var bomb_count_badge: Label
var _grenade_handler: WeaponHoldHandler
var _tracked_touches: Dictionary = {}

func _ready() -> void:
	_build_c4_button()
	_build_bomb_count_badge()
	_refresh_c4_button_visibility()
	if not _is_mobile_device():
		jump_button.pressed.connect(_on_jump_btn_pressed)
		attack_button.pressed.connect(_on_attack_btn_pressed)
		bomb_button.button_down.connect(_on_bomb_btn_pressed)
		bomb_button.button_up.connect(_on_bomb_btn_released)
		c4_button.button_down.connect(_on_c4_btn_pressed)
		c4_button.button_up.connect(_on_c4_btn_released)


func bind_grenade_counter(weapon_handler: WeaponHoldHandler) -> void:
	if weapon_handler == null:
		return
	if _grenade_handler != null and _grenade_handler.grenade_count_changed.is_connected(_on_grenade_count_changed):
		_grenade_handler.grenade_count_changed.disconnect(_on_grenade_count_changed)
	_grenade_handler = weapon_handler
	if not _grenade_handler.grenade_count_changed.is_connected(_on_grenade_count_changed):
		_grenade_handler.grenade_count_changed.connect(_on_grenade_count_changed)
	_on_grenade_count_changed(_grenade_handler.get_grenade_count())


func _input(event: InputEvent) -> void:
	if not _is_mobile_device():
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_handle_touch_pressed(event)
		else:
			if _tracked_touches.get(event.index, &"") == &"bomb":
				bomb_released.emit()
			elif _tracked_touches.get(event.index, &"") == &"c4":
				c4_released.emit()
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

	if c4_button.visible and c4_button.get_global_rect().has_point(event.position):
		_tracked_touches[event.index] = &"c4"
		c4_pressed.emit()
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


func _on_bomb_btn_released() -> void:
	bomb_released.emit()


func _build_c4_button() -> void:
	if c4_button != null:
		return
	c4_button = TextureButton.new()
	c4_button.name = "C4Btn"
	c4_button.texture_normal = C4_BUTTON_TEXTURE
	c4_button.texture_pressed = C4_BUTTON_TEXTURE
	c4_button.texture_hover = C4_BUTTON_TEXTURE
	c4_button.ignore_texture_size = true
	c4_button.stretch_mode = 0
	c4_button.position = Vector2(56.0, -78.0)
	c4_button.size = Vector2(70.0, 70.0)
	c4_button.z_index = 5
	c4_button.tooltip_text = "C4"
	add_child(c4_button)


func _build_bomb_count_badge() -> void:
	if bomb_count_badge != null:
		return
	bomb_count_badge = Label.new()
	bomb_count_badge.name = "BombCountBadge"
	bomb_count_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bomb_count_badge.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	bomb_count_badge.offset_left = -30.0
	bomb_count_badge.offset_top = -28.0
	bomb_count_badge.offset_right = -2.0
	bomb_count_badge.offset_bottom = -2.0
	bomb_count_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bomb_count_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bomb_count_badge.text = "3"
	bomb_count_badge.add_theme_font_size_override("font_size", 16)
	bomb_count_badge.add_theme_color_override("font_color", Color.WHITE)
	bomb_count_badge.add_theme_color_override("font_outline_color", Color.BLACK)
	bomb_count_badge.add_theme_constant_override("outline_size", 2)
	var badge_style: StyleBoxFlat = StyleBoxFlat.new()
	badge_style.bg_color = Color(0.0, 0.0, 0.0, 0.72)
	badge_style.corner_radius_top_left = 12
	badge_style.corner_radius_top_right = 12
	badge_style.corner_radius_bottom_left = 12
	badge_style.corner_radius_bottom_right = 12
	bomb_count_badge.add_theme_stylebox_override("normal", badge_style)
	bomb_button.add_child(bomb_count_badge)


func _refresh_c4_button_visibility() -> void:
	if c4_button == null:
		return
	c4_button.visible = NetworkManager.is_search_destroy_mode()


func _on_c4_btn_pressed() -> void:
	c4_pressed.emit()


func _on_c4_btn_released() -> void:
	c4_released.emit()


func _on_grenade_count_changed(count: int) -> void:
	if bomb_count_badge == null:
		return
	bomb_count_badge.text = str(maxi(count, 0))
	bomb_count_badge.visible = bomb_button.visible
