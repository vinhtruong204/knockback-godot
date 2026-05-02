class_name WeaponHoldHandler extends Node2D

const DEFAULT_DAMAGE: int = 50
const DEFAULT_FIRE_RATE: float = 5.0
const RELOAD_DELAY: float = 1.5
const GRENADE_MAX_COUNT: int = 3
const SECONDARY_RESERVE_INFINITE: int = -1
const DEFAULT_PRIMARY_AMMO: int = 30
const DEFAULT_SECONDARY_AMMO: int = 12

@export var player_input: PlayerInput

@onready var current_weapon_node: Node2D = $Primary
@export var current_weapon_type: SwitchWeaponHandler.WeaponType = SwitchWeaponHandler.WeaponType.PRIMARY:
	set(value):
		# Hide older weapon
		current_weapon_node.hide()

		# Set new weapon type
		current_weapon_type = value

		# Change to new weapon node
		match value:
			SwitchWeaponHandler.WeaponType.PRIMARY:
				current_weapon_node = $Primary
			SwitchWeaponHandler.WeaponType.SECONDARY:
				current_weapon_node = $Secondary
			SwitchWeaponHandler.WeaponType.MELEE:
				current_weapon_node = $Melee

		# Show new weapon
		current_weapon_node.show()

# {slot_type: {"damage": int, "fire_rate": float}}
var _stats_by_slot: Dictionary = {}

# {slot_type: {"mag", "mag_max", "reserve", "reserve_max", "is_reloading"}}
var _ammo_by_slot: Dictionary = {}

var _grenade_count: int = GRENADE_MAX_COUNT

signal ammo_changed(slot: String, mag: int, reserve: int)
signal grenade_count_changed(count: int)
signal active_slot_changed(slot: String)
signal out_of_ammo(slot: String)


func _ready() -> void:
	if not is_multiplayer_authority(): return

	player_input.switch_weapon.connect(_on_switch_weapon)

	# Instant-start / no-API path: PlayerSpawner did not call set_weapon_loadout
	# because the weapons dict was empty. Seed defaults so the UI has ammo text
	# to show and consume_ammo lets the player fire. _init_ammo_for_slot emits
	# ammo_changed, which the already-bound SwitchWeaponHandler picks up.
	_seed_default_ammo_if_missing()


func _seed_default_ammo_if_missing() -> void:
	if not _ammo_by_slot.has(Enums.SlotType.PRIMARY):
		_init_ammo_for_slot(Enums.SlotType.PRIMARY, {"ammo": DEFAULT_PRIMARY_AMMO})
	if not _ammo_by_slot.has(Enums.SlotType.SECONDARY):
		_init_ammo_for_slot(Enums.SlotType.SECONDARY, {"ammo": DEFAULT_SECONDARY_AMMO})


func _on_switch_weapon(weapon_type: SwitchWeaponHandler.WeaponType) -> void:
	self.current_weapon_type = weapon_type


func set_weapon_loadout(weapons: Dictionary) -> void:
	for slot_type in weapons:
		var info: Dictionary = weapons[slot_type]
		var image_name: String = info.get("image", "")
		if image_name != "":
			var tex = load("res://assets/game/weapon/static/%s" % image_name)
			if tex:
				match slot_type:
					Enums.SlotType.PRIMARY:
						$Primary.get_child(0).texture = tex
					Enums.SlotType.SECONDARY:
						$Secondary.get_child(0).texture = tex
					Enums.SlotType.MELEE:
						$Melee.get_child(0).texture = tex
		_stats_by_slot[slot_type] = {
			"damage": int(info.get("damage", DEFAULT_DAMAGE)),
			"fire_rate": float(info.get("fire_rate", DEFAULT_FIRE_RATE)),
		}
		_init_ammo_for_slot(slot_type, info)


func get_active_stats() -> Dictionary:
	var slot := _slot_for_weapon_type(current_weapon_type)
	return _stats_by_slot.get(slot, {
		"damage": DEFAULT_DAMAGE,
		"fire_rate": DEFAULT_FIRE_RATE,
	})


func get_ammo_state(slot: String) -> Dictionary:
	return _ammo_by_slot.get(slot, {})


func get_grenade_count() -> int:
	return _grenade_count


# Returns true if the shot/swing is allowed.
func consume_ammo() -> bool:
	var slot := _slot_for_weapon_type(current_weapon_type)
	if slot == Enums.SlotType.MELEE:
		return true
	# Defensive seed: if the slot has no ammo state yet (e.g. _ready ran before
	# authority was set on this node, or instant-start with empty weapons), seed
	# defaults now so firing isn't silently blocked.
	if not _ammo_by_slot.has(slot):
		_seed_default_ammo_if_missing()
	var s: Dictionary = _ammo_by_slot.get(slot, {})
	if s.is_empty() or bool(s.get("is_reloading", false)):
		return false
	if int(s.get("mag", 0)) <= 0:
		_try_start_reload(slot)
		return false
	s["mag"] = int(s["mag"]) - 1
	_ammo_by_slot[slot] = s
	ammo_changed.emit(slot, int(s["mag"]), int(s["reserve"]))
	if int(s["mag"]) <= 0:
		_try_start_reload(slot)
	return true


func consume_grenade() -> bool:
	if _grenade_count <= 0:
		return false
	_grenade_count -= 1
	grenade_count_changed.emit(_grenade_count)
	return true


func reset_ammo_and_active() -> void:
	for slot in _ammo_by_slot.keys():
		var s: Dictionary = _ammo_by_slot[slot]
		s["mag"] = int(s.get("mag_max", 0))
		s["reserve"] = int(s.get("reserve_max", 0))
		s["is_reloading"] = false
		_ammo_by_slot[slot] = s
		ammo_changed.emit(slot, int(s["mag"]), int(s["reserve"]))
	_grenade_count = GRENADE_MAX_COUNT
	grenade_count_changed.emit(_grenade_count)
	if current_weapon_type != SwitchWeaponHandler.WeaponType.PRIMARY:
		self.current_weapon_type = SwitchWeaponHandler.WeaponType.PRIMARY
		active_slot_changed.emit(Enums.SlotType.PRIMARY)


func _init_ammo_for_slot(slot: String, info: Dictionary) -> void:
	var capacity := int(info.get("ammo", 0))
	var infinite_reserve := slot == Enums.SlotType.SECONDARY
	_ammo_by_slot[slot] = {
		"mag": capacity,
		"mag_max": capacity,
		"reserve": SECONDARY_RESERVE_INFINITE if infinite_reserve else capacity,
		"reserve_max": SECONDARY_RESERVE_INFINITE if infinite_reserve else capacity,
		"is_reloading": false,
	}
	ammo_changed.emit(slot, int(_ammo_by_slot[slot]["mag"]), int(_ammo_by_slot[slot]["reserve"]))


func _try_start_reload(slot: String) -> void:
	var s: Dictionary = _ammo_by_slot[slot]
	var infinite := int(s.get("reserve", 0)) == SECONDARY_RESERVE_INFINITE
	if not infinite and int(s.get("reserve", 0)) <= 0:
		# Literal 0/0 — out of ammo entirely
		out_of_ammo.emit(slot)
		_try_auto_switch(slot)
		return
	s["is_reloading"] = true
	_ammo_by_slot[slot] = s
	await get_tree().create_timer(RELOAD_DELAY).timeout
	if not is_inside_tree():
		return
	var s2: Dictionary = _ammo_by_slot[slot]
	var to_load := int(s2["mag_max"]) - int(s2["mag"])
	if int(s2["reserve"]) == SECONDARY_RESERVE_INFINITE:
		s2["mag"] = int(s2["mag_max"])
	else:
		var taken: int = min(to_load, int(s2["reserve"]))
		s2["mag"] = int(s2["mag"]) + taken
		s2["reserve"] = int(s2["reserve"]) - taken
	s2["is_reloading"] = false
	_ammo_by_slot[slot] = s2
	ammo_changed.emit(slot, int(s2["mag"]), int(s2["reserve"]))


func _try_auto_switch(empty_slot: String) -> void:
	# Per spec: only auto-switch from primary on the literal 0/0 state.
	if empty_slot != Enums.SlotType.PRIMARY:
		return
	var next_type := SwitchWeaponHandler.WeaponType.SECONDARY
	if next_type == current_weapon_type:
		return
	self.current_weapon_type = next_type
	active_slot_changed.emit(_slot_for_weapon_type(next_type))


func _slot_for_weapon_type(weapon_type: SwitchWeaponHandler.WeaponType) -> String:
	match weapon_type:
		SwitchWeaponHandler.WeaponType.PRIMARY:
			return Enums.SlotType.PRIMARY
		SwitchWeaponHandler.WeaponType.SECONDARY:
			return Enums.SlotType.SECONDARY
		SwitchWeaponHandler.WeaponType.MELEE:
			return Enums.SlotType.MELEE
	return Enums.SlotType.PRIMARY
