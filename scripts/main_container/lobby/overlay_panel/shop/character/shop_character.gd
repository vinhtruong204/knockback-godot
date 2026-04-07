class_name ShopCharacter extends Control

@export var shop_character_item: PackedScene
@onready var shop_character_container: GridContainer = $ScrollContainer/VBoxContainer/GridContainer

func _ready():
	load_shop_characters()

func load_shop_characters():
	var currency_ui: CurrencyContainer = %UIButtons/TopBar/CurrencyContainer
	EconomyApi.get_shop_items(func(response: Dictionary) -> void:
		if response.get("ok", false):
			var data = response.get("data", [])
			for item in data:
				var shop_character_item_instance = shop_character_item.instantiate()
				shop_character_container.add_child(shop_character_item_instance)
				shop_character_item_instance.currency_ui = currency_ui
				shop_character_item_instance.set_shop_item(item)
		else:
			print("Failed to get shop items")
	, Enums.ItemType.CHARACTER)
