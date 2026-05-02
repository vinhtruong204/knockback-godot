class_name ShopItems extends Control

@export var shop_item: PackedScene
@onready var shop_container: GridContainer = $ScrollContainer/VBoxContainer/GridContainer

func _ready():
	load_shop_items()

func load_shop_items():
	var currency_ui: CurrencyContainer = %UIButtons/TopBar/CurrencyContainer
	var pid := ApiManager.player_id
	PlayerApi.get_inventory_by_type(pid, Enums.ItemType.ITEM, func(inv_response: Dictionary):
		var owned_ids := {}
		if inv_response.get("ok", false):
			for inv_item in inv_response.get("data", []):
				owned_ids[int(inv_item.get("item_id", 0))] = true
		else:
			print("[ShopItems] Inventory fetch failed: ", inv_response.get("error", ""))
		print("[ShopItems] owned_ids: ", owned_ids)
		_load_items(currency_ui, owned_ids)
	)


func _load_items(currency_ui: CurrencyContainer, owned_ids: Dictionary) -> void:
	EconomyApi.get_shop_items(func(response: Dictionary) -> void:
		if response.get("ok", false):
			var data = response.get("data", [])
			for item in data:
				var shop_item_instance = shop_item.instantiate()
				shop_container.add_child(shop_item_instance)
				shop_item_instance.currency_ui = currency_ui
				shop_item_instance.set_shop_item(item, owned_ids)
		else:
			print("[ShopItems] Failed to get shop items")
	, Enums.ItemType.ITEM)
