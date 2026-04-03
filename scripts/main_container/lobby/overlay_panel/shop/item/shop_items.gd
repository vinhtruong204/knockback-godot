class_name ShopItems extends Control

@export var shop_item: PackedScene
@onready var shop_container: GridContainer = $ScrollContainer/VBoxContainer/GridContainer

func _ready():
	load_shop_items()

func load_shop_items():
	EconomyApi.get_shop_items(func(response: Dictionary) -> void:
		if response.get("ok", false):
			var data = response.get("data", [])
			for item in data:
				var shop_item_instance = shop_item.instantiate()
				shop_container.add_child(shop_item_instance)
				shop_item_instance.set_shop_item(item)
		else:
			print("Failed to get shop items")
	, Enums.ItemType.ITEM)
