class_name SwitchWeaponHandler extends Control

enum WeaponType { PRIMARY, SECONDARY, MELEE }

#region Signal
signal weapon_switched(weapon: SwitchWeaponHandler.WeaponType)
#endregion

@onready var current_weapon_button: Button = $CurrentWeaponBtn

#region Panel
@onready var select_weapon_panel: Panel = $SelectWeaponPanel
var _is_select_weapon_panel_visible: bool = false

@onready var primary_button: Button = $SelectWeaponPanel/VBoxContainer/PrimaryBtn
@onready var secondary_button: Button = $SelectWeaponPanel/VBoxContainer/SecondaryBtn
@onready var melee_button: Button = $SelectWeaponPanel/VBoxContainer/MeleeBtn
#endregion

# {slot: {"icon": Texture2D}}
var _loadout: Dictionary = {}
var _active_slot: String = Enums.SlotType.PRIMARY
var _weapon_handler_ref: WeaponHoldHandler


func _ready() -> void:
	current_weapon_button.pressed.connect(_on_current_weapon_button_pressed)

	primary_button.pressed.connect(_on_weapon_button_pressed.bind(Enums.SlotType.PRIMARY))
	secondary_button.pressed.connect(_on_weapon_button_pressed.bind(Enums.SlotType.SECONDARY))
	melee_button.pressed.connect(_on_weapon_button_pressed.bind(Enums.SlotType.MELEE))


func bind_local_player(weapon_handler: WeaponHoldHandler, weapons_loadout: Dictionary) -> void:
	_weapon_handler_ref = weapon_handler
	_reset_buttons()
	_build_loadout(weapons_loadout)
	_refresh_button(primary_button, Enums.SlotType.PRIMARY)
	_refresh_button(secondary_button, Enums.SlotType.SECONDARY)
	_refresh_button(melee_button, Enums.SlotType.MELEE)
	_set_active(Enums.SlotType.PRIMARY)
	if not weapon_handler.ammo_changed.is_connected(_on_ammo_changed):
		weapon_handler.ammo_changed.connect(_on_ammo_changed)
	if not weapon_handler.active_slot_changed.is_connected(_on_active_slot_changed):
		weapon_handler.active_slot_changed.connect(_on_active_slot_changed)


func _build_loadout(weapons_loadout: Dictionary) -> void:
	_loadout.clear()
	for slot_key in weapons_loadout:
		var slot := str(slot_key)
		var info: Dictionary = weapons_loadout[slot_key]
		var image_name: String = info.get("image", "")
		var icon := _load_weapon_icon(image_name, slot, int(info.get("weapon_id", 0)))
		_loadout[slot] = {"icon": icon}


func _refresh_button(btn: Button, slot: String) -> void:
	var entry: Dictionary = _loadout.get(slot, {})
	var icon = entry.get("icon", null)
	btn.icon = icon
	btn.text = _format_ammo_text(slot)


func _format_ammo_text(slot: String) -> String:
	if slot == Enums.SlotType.MELEE:
		return ""
	if _weapon_handler_ref == null:
		return ""
	var s: Dictionary = _weapon_handler_ref.get_ammo_state(slot)
	if s.is_empty():
		return ""
	var mag := int(s.get("mag", 0))
	var reserve := int(s.get("reserve", 0))
	if reserve == WeaponHoldHandler.SECONDARY_RESERVE_INFINITE:
		return "%d/∞" % mag
	return "%d/%d" % [mag, reserve]


func _set_active(slot: String) -> void:
	_active_slot = slot
	var entry: Dictionary = _loadout.get(slot, {})
	var icon = entry.get("icon", null)
	current_weapon_button.icon = icon
	if slot == Enums.SlotType.MELEE:
		current_weapon_button.text = ""
	else:
		current_weapon_button.text = _format_ammo_text(slot)
	weapon_switched.emit(_weapon_type_for_slot(slot))


func _weapon_type_for_slot(slot: String) -> WeaponType:
	match slot:
		Enums.SlotType.PRIMARY:
			return WeaponType.PRIMARY
		Enums.SlotType.SECONDARY:
			return WeaponType.SECONDARY
		Enums.SlotType.MELEE:
			return WeaponType.MELEE
	return WeaponType.PRIMARY


func _on_current_weapon_button_pressed() -> void:
	if _is_select_weapon_panel_visible:
		select_weapon_panel.hide()
		_is_select_weapon_panel_visible = false
	else:
		select_weapon_panel.show()
		_is_select_weapon_panel_visible = true


func _on_weapon_button_pressed(slot: String) -> void:
	# Hide popup
	select_weapon_panel.hide()
	_is_select_weapon_panel_visible = false
	if slot == _active_slot:
		return
	_set_active(slot)


func _on_ammo_changed(slot: String, _mag: int, _reserve: int) -> void:
	# Refresh popup button text for that slot
	match slot:
		Enums.SlotType.PRIMARY:
			primary_button.text = _format_ammo_text(slot)
		Enums.SlotType.SECONDARY:
			secondary_button.text = _format_ammo_text(slot)
		Enums.SlotType.MELEE:
			melee_button.text = ""
	# Refresh bottom button if it's the active slot
	if slot == _active_slot:
		if slot == Enums.SlotType.MELEE:
			current_weapon_button.text = ""
		else:
			current_weapon_button.text = _format_ammo_text(slot)


func _on_active_slot_changed(slot: String) -> void:
	# WeaponHoldHandler auto-switched (e.g. primary 0/0). Sync UI without
	# re-emitting weapon_switched (the handler already changed its own state).
	_active_slot = slot
	var entry: Dictionary = _loadout.get(slot, {})
	var icon = entry.get("icon", null)
	current_weapon_button.icon = icon
	if slot == Enums.SlotType.MELEE:
		current_weapon_button.text = ""
	else:
		current_weapon_button.text = _format_ammo_text(slot)


func _reset_buttons() -> void:
	for btn in [current_weapon_button, primary_button, secondary_button, melee_button]:
		btn.icon = null
		btn.text = ""


func _load_weapon_icon(image_name: String, slot: String, weapon_id: int) -> Texture2D:
	if image_name == "":
		print("[SwitchWeaponHandler] Empty icon image for weapon ", weapon_id, " slot ", slot)
		return null
	var path := "res://assets/game/weapon/static/%s" % image_name
	if not ResourceLoader.exists(path):
		print("[SwitchWeaponHandler] Missing weapon icon ", path, " for weapon ", weapon_id, " slot ", slot)
		return null
	var tex = load(path)
	if tex is Texture2D:
		return tex
	print("[SwitchWeaponHandler] Invalid weapon icon ", path, " for weapon ", weapon_id, " slot ", slot)
	return null
