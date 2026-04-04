class_name EquipmentPanel extends Panel

@export var equipment_item: PackedScene
@onready var item_container: GridContainer = $SelectControl/Panel/ScrollContainer/VBoxContainer/GridContainer
var current_item_type: String = Enums.ItemType.WEAPON

@onready var primary_texture: TextureRect = $EquipmentContainer/Primary/TextureRect
@onready var secondary_texture: TextureRect = $EquipmentContainer/Secondary/TextureRect
@onready var melee_texture: TextureRect = $EquipmentContainer/Melee/TextureRect
@onready var grenade_texture: TextureRect = $ItemContainer/Item1/TextureRect

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

func _on_item_selected(item_details: Dictionary) -> void:
	print(item_details)
	# match item_details["slot_type"]:
	# 	Enums.SlotType.PRIMARY:
	# 		primary_texture.texture = load(item_details["texture"])
	# 	Enums.SlotType.SECONDARY:
	# 		secondary_texture.texture = load(item_details["texture"])
	# 	Enums.SlotType.MELEE:
	# 		melee_texture.texture = load(item_details["texture"])
	# 	Enums.SlotType.GRENADE:
	# 		grenade_texture.texture = load(item_details["texture"])
	# 	Enums.SlotType.CHARACTER:
	# 		pass


func _on_weapon_btn_pressed():
	current_item_type = Enums.ItemType.WEAPON
	load_equipment_items()

func _on_item_btn_pressed():
	current_item_type = Enums.ItemType.ITEM
	load_equipment_items()

func _on_character_btn_pressed():
	current_item_type = Enums.ItemType.CHARACTER
	load_equipment_items()
