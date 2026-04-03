class_name ShopWeaponItem extends Control

@onready var weapon_texture: TextureRect = $TextureRect
@onready var buy_button: Button = $BuyButton

func set_shop_item(item: Dictionary) -> void:
	# weapon_texture.texture = load(item["image"])
	var price = int(item.get("price", 0))
	var currency_type = item.get("currency_type", "")
	
	buy_button.text = str(price)
	buy_button.icon = load("res://assets/lobby/top_bar/currency/%s.png" % currency_type)
