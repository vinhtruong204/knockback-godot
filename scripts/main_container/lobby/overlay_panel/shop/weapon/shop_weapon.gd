class_name ShopWeapon extends Control

@export var shop_weapon_item: PackedScene
@onready var shop_weapon_container: GridContainer = $ScrollContainer/VBoxContainer/GridContainer

func _ready():
	load_shop_weapons()

func load_shop_weapons():
	var currency_ui: CurrencyContainer = %UIButtons/TopBar/CurrencyContainer
	var pid := ApiManager.player_id
	PlayerApi.get_inventory_by_type(pid, Enums.ItemType.WEAPON, func(inv_response: Dictionary):
		var owned_ids := {}
		if inv_response.get("ok", false):
			for inv_item in inv_response.get("data", []):
				owned_ids[int(inv_item.get("item_id", 0))] = true
		else:
			print("[ShopWeapon] Inventory fetch failed: ", inv_response.get("error", ""))
		print("[ShopWeapon] owned_ids: ", owned_ids)
		_load_weapons(currency_ui, owned_ids)
	)


func _load_weapons(currency_ui: CurrencyContainer, owned_ids: Dictionary) -> void:
	EconomyApi.get_shop_items(func(response: Dictionary) -> void:
		if response.get("ok", false):
			var data = response.get("data", [])
			for item in data:
				var shop_weapon_item_instance = shop_weapon_item.instantiate()
				shop_weapon_container.add_child(shop_weapon_item_instance)
				shop_weapon_item_instance.currency_ui = currency_ui
				shop_weapon_item_instance.set_shop_item(item, owned_ids)
		else:
			print("[ShopWeapon] Failed to get shop items")
	, Enums.ItemType.WEAPON)
