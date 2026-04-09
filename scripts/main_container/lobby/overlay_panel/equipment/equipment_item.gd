class_name EquipmentItem extends TextureButton

signal item_selected(item: EquipmentItem)

@onready var equip_btn: Button = $EquipBtn
var _item_data: Dictionary
var item_details: Dictionary

func _ready() -> void:
	equip_btn.pressed.connect(_on_equip_btn_pressed)


'''
{ "player_id": "a4f1a0d4-6f4a-4892-b069-2271ee433d50", "item_id": 52.0, "item_type": "weapon", "quantity": 1.0, "obtain_at": "2026-03-17T15:32:51.710995Z" }{ "damage": 33.0, "fire_rate": 11.0, "name": "M4A1", "weapon_id": 52.0, "weapon_type": "primary" }
{ "damage": 33.0, "fire_rate": 11.0, "name": "M4A1", "weapon_id": 52.0, "weapon_type": "primary" }
'''
func _on_equip_btn_pressed() -> void:
	var item_type = _item_data.get("item_type")

	match item_type:
		Enums.ItemType.WEAPON:
			var slot := str(item_details["weapon_type"])
			var weapon_id := int(_item_data["item_id"])
			PlayerApi.equip_item({"player_id": ApiManager.player_id, "slot_type": slot, "weapon_id": weapon_id}, func(response: Dictionary) -> void:
				if response.get("ok", false):
					print("Item equipped successfully")
				else:
					PlayerApi.update_equipment(ApiManager.player_id, slot, {"weapon_id": weapon_id}, func(update_response: Dictionary) -> void:
						if update_response.get("ok", false):
							print("Item equipped successfully")
						else:
							print("Failed to equip _item_data")
					)
			)

		Enums.ItemType.CHARACTER:
			var character_id := int(_item_data["item_id"])
			PlayerApi.select_character({"player_id": ApiManager.player_id, "character_id": character_id}, func(response: Dictionary) -> void:
				if response.get("ok", false):
					print("Item equipped successfully")
				else:
					PlayerApi.update_selected_character(ApiManager.player_id, {"character_id": character_id}, func(update_response: Dictionary) -> void:
						if update_response.get("ok", false):
							print("Item equipped successfully")
						else:
							print("Failed to equip character")
					)
			)

	# Emit to update equipment panel
	item_selected.emit(self )


func set_equipment_item(item_data: Dictionary) -> void:
	_item_data = item_data

	# Get _item_data details from economy api
	match _item_data["item_type"]:
		Enums.ItemType.WEAPON:
			ConfigApi.get_weapon(_item_data["item_id"], func(response: Dictionary) -> void:
				if response.get("ok", false):
					item_details = response.get("data", {})
					var image_name = item_details.get("image", "")
					if image_name != "":
						texture_normal = load("res://assets/game/weapon/static/%s" % image_name)
				else:
					print("Failed to get item_data details")
			)
		Enums.ItemType.CHARACTER:
			ConfigApi.get_character(_item_data["item_id"], func(response: Dictionary) -> void:
				if response.get("ok", false):
					item_details = response.get("data", {})
					var texture_name = item_details.get("texture", "")
					if texture_name != "":
						texture_normal = load("res://assets/game/player/%s" % texture_name)
				else:
					print("Failed to get item_data details")
			)
