class_name ShopWeapon extends Control

@export var shop_weapon_item: PackedScene
@onready var shop_weapon_container: GridContainer = $ScrollContainer/VBoxContainer/GridContainer

func _ready():
	load_shop_weapons()

func load_shop_weapons():
	var currency_ui: CurrencyContainer = %UIButtons/TopBar/CurrencyContainer
	EconomyApi.get_shop_items(func(response: Dictionary) -> void:
		if response.get("ok", false):
			var data = response.get("data", [])
			for item in data:
				var shop_weapon_item_instance = shop_weapon_item.instantiate()
				shop_weapon_container.add_child(shop_weapon_item_instance)
				shop_weapon_item_instance.currency_ui = currency_ui
				shop_weapon_item_instance.set_shop_item(item)
		else:
			print("Failed to get shop items")
	, Enums.ItemType.WEAPON)
