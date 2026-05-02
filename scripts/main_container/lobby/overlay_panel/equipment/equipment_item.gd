class_name EquipmentItem extends TextureButton

signal item_selected(item: EquipmentItem)

@onready var equip_btn: Button = $EquipBtn
var _item_data: Dictionary
var item_details: Dictionary

func _ready() -> void:
	equip_btn.pressed.connect(_on_equip_btn_pressed)
	pressed.connect(_on_texture_pressed)


func _on_equip_btn_pressed() -> void:
	var item_type = _item_data.get("item_type")
	equip_btn.disabled = true

	match item_type:
		Enums.ItemType.WEAPON:
			var slot := str(item_details["weapon_type"])
			var weapon_id := int(_item_data["item_id"])
			PlayerApi.equip_item({"player_id": ApiManager.player_id, "slot_type": slot, "weapon_id": weapon_id}, func(response: Dictionary) -> void:
				if response.get("ok", false):
					equip_btn.disabled = false
					item_selected.emit(self)
				else:
					PlayerApi.update_equipment(ApiManager.player_id, slot, {"weapon_id": weapon_id}, func(update_response: Dictionary) -> void:
						equip_btn.disabled = false
						if update_response.get("ok", false):
							item_selected.emit(self)
						else:
							print("Failed to equip weapon")
					)
			)

		Enums.ItemType.CHARACTER:
			var character_id := int(_item_data["item_id"])
			PlayerApi.select_character({"player_id": ApiManager.player_id, "character_id": character_id}, func(response: Dictionary) -> void:
				if response.get("ok", false):
					equip_btn.disabled = false
					item_selected.emit(self)
				else:
					PlayerApi.update_selected_character(ApiManager.player_id, {"character_id": character_id}, func(update_response: Dictionary) -> void:
						equip_btn.disabled = false
						if update_response.get("ok", false):
							item_selected.emit(self)
						else:
							print("Failed to equip character")
					)
			)


func _on_texture_pressed() -> void:
	if item_details.is_empty():
		return
	var item_id = int(_item_data.get("item_id", 0))
	var item_type = _item_data.get("item_type", "")
	var global_ui: GlobalUI = get_tree().root.get_node("Main/GlobalUi")
	# Show detail panel in view-only mode (owned item, no buy action)
	global_ui.show_item_detail(item_id, item_type, 0, "", Callable(), true)


func _set_all_textures(tex: Texture2D) -> void:
	texture_normal = tex
	texture_pressed = tex
	texture_hover = tex


func set_equipment_item(item_data: Dictionary) -> void:
	_item_data = item_data

	match _item_data["item_type"]:
		Enums.ItemType.WEAPON:
			ConfigApi.get_weapon(_item_data["item_id"], func(response: Dictionary) -> void:
				if response.get("ok", false):
					item_details = response.get("data", {})
					var image_name = item_details.get("image", "")
					if image_name != "":
						_set_all_textures(load("res://assets/game/weapon/static/%s" % image_name))
				else:
					print("Failed to get item_data details")
			)
		Enums.ItemType.CHARACTER:
			ConfigApi.get_character(_item_data["item_id"], func(response: Dictionary) -> void:
				if response.get("ok", false):
					item_details = response.get("data", {})
					var texture_name = item_details.get("texture", "")
					if texture_name != "":
						_set_all_textures(load("res://assets/game/player/%s" % texture_name))
				else:
					print("Failed to get item_data details")
			)
