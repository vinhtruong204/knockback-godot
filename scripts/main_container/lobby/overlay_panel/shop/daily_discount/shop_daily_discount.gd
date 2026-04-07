class_name DailyDiscount extends Control


@export var shop_discount_item: PackedScene
@onready var shop_discount_container: GridContainer = $GridContainer

func _ready():
	load_shop_discounts()

func load_shop_discounts():
	var currency_ui: CurrencyContainer = %UIButtons/TopBar/CurrencyContainer
	EconomyApi.get_shop_items(func(response: Dictionary) -> void:
		if response.get("ok", false):
			var data = response.get("data", [])
			for item in data:
				if item.get("discount", 0) > 0:
					var shop_discount_item_instance = shop_discount_item.instantiate()
					shop_discount_container.add_child(shop_discount_item_instance)
					shop_discount_item_instance.currency_ui = currency_ui
					shop_discount_item_instance.set_shop_item(item)
		else:
			print("Failed to get daily discount")
	)
