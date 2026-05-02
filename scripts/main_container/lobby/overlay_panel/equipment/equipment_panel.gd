class_name EquipmentPanel extends Panel

@export var equipment_item: PackedScene
@onready var item_container: GridContainer = $SelectControl/Panel/ScrollContainer/VBoxContainer/GridContainer
var current_item_type: String = Enums.ItemType.WEAPON

# weapon
@onready var primary_texture: TextureRect = $EquipmentContainer/Primary/TextureRect
@onready var secondary_texture: TextureRect = $EquipmentContainer/Secondary/TextureRect
@onready var melee_texture: TextureRect = $EquipmentContainer/Melee/TextureRect
@onready var grenade_texture: TextureRect = $ItemContainer/Item1/TextureRect

# character
@onready var character_team_1_btn: TextureButton = $CharacterContainer/Team1Btn
@onready var character_weapon_overlay: TextureRect = $CharacterContainer/Team1Btn/WeaponOverlay

# Track equipped item IDs for detail panel
var _equipped_weapon_ids: Dictionary = {}  # slot_type -> weapon_id
var _equipped_character_id: int = 0

func _ready():
	load_equipped_display()
	load_equipment_items()
	_setup_slot_click_handlers()
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if visible:
		load_equipped_display()
		# Reload the inventory grid each time the panel opens so newly purchased
		# items from the Shop appear immediately. PlayerApi.purchase_item already
		# invalidates the player_dynamic cache, so this call hits the API fresh.
		load_equipment_items()


func _setup_slot_click_handlers():
	for tex_rect in [primary_texture, secondary_texture, melee_texture, grenade_texture]:
		tex_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		tex_rect.gui_input.connect(_on_slot_texture_input.bind(tex_rect))
	character_team_1_btn.pressed.connect(_on_character_slot_pressed)


func _on_slot_texture_input(event: InputEvent, tex_rect: TextureRect) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var slot_type := ""
	if tex_rect == primary_texture:
		slot_type = Enums.SlotType.PRIMARY
	elif tex_rect == secondary_texture:
		slot_type = Enums.SlotType.SECONDARY
	elif tex_rect == melee_texture:
		slot_type = Enums.SlotType.MELEE
	elif tex_rect == grenade_texture:
		slot_type = Enums.SlotType.GRENADE
	var weapon_id = _equipped_weapon_ids.get(slot_type, 0)
	if weapon_id > 0:
		var global_ui: GlobalUI = get_tree().root.get_node("Main/GlobalUi")
		global_ui.show_item_detail(weapon_id, Enums.ItemType.WEAPON, 0, "", Callable(), true)


func _on_character_slot_pressed() -> void:
	if _equipped_character_id > 0:
		var global_ui: GlobalUI = get_tree().root.get_node("Main/GlobalUi")
		global_ui.show_item_detail(_equipped_character_id, Enums.ItemType.CHARACTER, 0, "", Callable(), true)


func load_equipped_display():
	var pid := ApiManager.player_id

	# Load equipped weapons per slot (force refresh to always get latest from API)
	PlayerApi.get_player_equipment(pid, func(response: Dictionary):
		if not response.get("ok", false):
			print("Failed to load equipment: ", response.get("error", ""))
			return
		for equip in response.get("data", []):
			var slot_type = equip.get("slot_type", "")
			var weapon_id = int(equip.get("weapon_id", 0))
			if weapon_id <= 0 or slot_type == Enums.SlotType.CHARACTER:
				continue
			_equipped_weapon_ids[slot_type] = weapon_id
			_load_slot_texture(weapon_id, slot_type)
			if slot_type == Enums.SlotType.PRIMARY:
				_refresh_primary_overlay(weapon_id)
	, true)

	# Load selected character (force refresh)
	PlayerApi.get_selected_character(pid, func(response: Dictionary):
		if not response.get("ok", false):
			return
		var character_id = int(response.get("data", {}).get("character_id", 0))
		if character_id <= 0:
			return
		_equipped_character_id = character_id
		ConfigApi.get_character(character_id, func(char_response: Dictionary):
			if not char_response.get("ok", false):
				return
			var texture_name = char_response.get("data", {}).get("texture", "")
			if texture_name == "":
				return
			var tex = load("res://assets/game/player/%s" % texture_name)
			character_team_1_btn.texture_normal = tex
			character_team_1_btn.texture_pressed = tex
			character_team_1_btn.texture_hover = tex
		)
	, true)


func _refresh_primary_overlay(weapon_id: int) -> void:
	# Updates the gun the character on Team1Btn is "holding". Hides the overlay
	# when no primary is equipped or the weapon image can't be resolved.
	if weapon_id <= 0:
		character_weapon_overlay.visible = false
		return
	ConfigApi.get_weapon(weapon_id, func(weapon_response: Dictionary):
		if not weapon_response.get("ok", false):
			character_weapon_overlay.visible = false
			return
		var image_name: String = weapon_response.get("data", {}).get("image", "")
		if image_name == "":
			character_weapon_overlay.visible = false
			return
		var tex = load("res://assets/game/weapon/static/%s" % image_name)
		if tex:
			character_weapon_overlay.texture = tex
			character_weapon_overlay.visible = true
	)


func _load_slot_texture(weapon_id: int, slot_type: String) -> void:
	ConfigApi.get_weapon(weapon_id, func(weapon_response: Dictionary):
		if not weapon_response.get("ok", false):
			return
		var image_name = weapon_response.get("data", {}).get("image", "")
		if image_name == "":
			return
		var tex = load("res://assets/game/weapon/static/%s" % image_name)
		match slot_type:
			Enums.SlotType.PRIMARY:
				primary_texture.texture = tex
			Enums.SlotType.SECONDARY:
				secondary_texture.texture = tex
			Enums.SlotType.MELEE:
				melee_texture.texture = tex
			Enums.SlotType.GRENADE:
				grenade_texture.texture = tex
	)


func load_equipment_items():
	# clear old items
	for item in item_container.get_children():
		item.queue_free()

	PlayerApi.get_inventory_by_type(ApiManager.player_id, current_item_type, func(response: Dictionary) -> void:
		if response.get("ok", false):
			var data = response.get("data", [])
			for item in data:
				var equipment_item_instance = equipment_item.instantiate()
				item_container.add_child(equipment_item_instance)
				equipment_item_instance.set_equipment_item(item)
				equipment_item_instance.item_selected.connect(_on_item_selected)
		else:
			print("Failed to get equipment items")
	)

func _on_item_selected(item: EquipmentItem) -> void:
	var item_type = item._item_data.get("item_type")
	var item_id = int(item._item_data.get("item_id", 0))

	match item_type:
		Enums.ItemType.WEAPON:
			var weapon_type = item.item_details.get("weapon_type", "")
			_equipped_weapon_ids[weapon_type] = item_id
			match weapon_type:
				Enums.SlotType.PRIMARY:
					primary_texture.texture = item.texture_normal
					# Mirror onto the character button overlay so the kept
					# Team1Btn shows the gun the character is holding.
					character_weapon_overlay.texture = item.texture_normal
					character_weapon_overlay.visible = item.texture_normal != null
				Enums.SlotType.SECONDARY:
					secondary_texture.texture = item.texture_normal
				Enums.SlotType.MELEE:
					melee_texture.texture = item.texture_normal
				Enums.SlotType.GRENADE:
					grenade_texture.texture = item.texture_normal
		Enums.ItemType.CHARACTER:
			_equipped_character_id = item_id
			character_team_1_btn.texture_normal = item.texture_normal
			character_team_1_btn.texture_pressed = item.texture_normal
			character_team_1_btn.texture_hover = item.texture_normal

func _on_weapon_btn_pressed():
	current_item_type = Enums.ItemType.WEAPON
	load_equipment_items()

func _on_item_btn_pressed():
	current_item_type = Enums.ItemType.ITEM
	load_equipment_items()

func _on_character_btn_pressed():
	current_item_type = Enums.ItemType.CHARACTER
	load_equipment_items()
