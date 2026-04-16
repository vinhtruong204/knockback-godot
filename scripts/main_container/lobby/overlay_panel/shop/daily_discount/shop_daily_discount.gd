class_name DailyDiscount extends Control


@export var shop_discount_item: PackedScene
@onready var shop_discount_container: GridContainer = $GridContainer

func _ready():
	load_shop_discounts()

func load_shop_discounts():
	var currency_ui: CurrencyContainer = %UIButtons/TopBar/CurrencyContainer
	var pid := ApiManager.player_id
	PlayerApi.get_player_inventory(pid, func(inv_response: Dictionary):
		var owned_ids := {}
		if inv_response.get("ok", false):
			for inv_item in inv_response.get("data", []):
				owned_ids[int(inv_item.get("item_id", 0))] = true
		else:
			print("[DailyDiscount] Inventory fetch failed: ", inv_response.get("error", ""))
		print("[DailyDiscount] owned_ids: ", owned_ids)
		_load_discount_items(currency_ui, owned_ids)
	)


func _load_discount_items(currency_ui: CurrencyContainer, owned_ids: Dictionary) -> void:
	EconomyApi.get_shop_items(func(response: Dictionary) -> void:
		if response.get("ok", false):
			var data = response.get("data", [])
			for item in data:
				if item.get("discount", 0) > 0:
					var shop_discount_item_instance = shop_discount_item.instantiate()
					shop_discount_container.add_child(shop_discount_item_instance)
					shop_discount_item_instance.currency_ui = currency_ui
					shop_discount_item_instance.set_shop_item(item, owned_ids)
		else:
			print("[DailyDiscount] Failed to get shop items")
	)
