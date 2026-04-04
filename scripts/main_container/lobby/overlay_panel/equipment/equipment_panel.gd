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
@onready var character_team_1_btn: Button = $CharacterContainer/Team1Btn
@onready var character_team_2_btn: Button = $CharacterContainer/Team2Btn

func _ready():
	load_equipment_items()

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
	
	match item_type:
		Enums.ItemType.WEAPON:
			match item.item_details.get("weapon_type"):
				Enums.SlotType.PRIMARY:
					primary_texture.texture = item.texture_normal
				Enums.SlotType.SECONDARY:
					secondary_texture.texture = item.texture_normal
				Enums.SlotType.MELEE:
					melee_texture.texture = item.texture_normal
				Enums.SlotType.GRENADE:
					grenade_texture.texture = item.texture_normal
		Enums.ItemType.CHARACTER:
			character_team_1_btn.icon = item.texture_normal
			character_team_2_btn.icon = item.texture_normal

func _on_weapon_btn_pressed():
	current_item_type = Enums.ItemType.WEAPON
	load_equipment_items()

func _on_item_btn_pressed():
	current_item_type = Enums.ItemType.ITEM
	load_equipment_items()

func _on_character_btn_pressed():
	current_item_type = Enums.ItemType.CHARACTER
	load_equipment_items()
