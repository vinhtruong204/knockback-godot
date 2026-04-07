class_name ShopCharacterItem extends Control

@onready var character_texture: TextureRect = $TextureRect
@onready var buy_button: Button = $BuyButton

var _item_data: Dictionary
var currency_ui: CurrencyContainer

func set_shop_item(item: Dictionary) -> void:
	_item_data = item
	# character_texture.texture = load(item["image"])
	var price = int(item.get("price", 0))
	var currency_type = item.get("currency_type", "")

	buy_button.text = str(price)
	buy_button.icon = load("res://assets/lobby/top_bar/currency/%s.png" % currency_type)
	buy_button.pressed.connect(_on_buy_pressed)


func _on_buy_pressed() -> void:
	var price = int(_item_data.get("price", 0))
	var currency_type = _item_data.get("currency_type", "")
	var item_type = _item_data.get("item_type", "")
	var global_ui: GlobalUI = get_tree().root.get_node("Main/GlobalUi")

	global_ui.show_confirm_purchase(item_type, price, currency_type, _do_purchase)


func _do_purchase() -> void:
	buy_button.disabled = true
	var price = int(_item_data.get("price", 0))
	var currency_type = _item_data.get("currency_type", "")
	var item_id = int(_item_data.get("item_id", 0))
	var item_type = _item_data.get("item_type", "")
	var global_ui: GlobalUI = get_tree().root.get_node("Main/GlobalUi")

	PlayerApi.purchase_item(
		{"item_id": item_id, "item_type": item_type, "currency_type": currency_type, "price": price},
		func(response: Dictionary) -> void:
			buy_button.disabled = false
			if response.get("ok", false):
				if currency_ui:
					currency_ui.update_currency()
				global_ui.show_purchase_notification(item_type, price, currency_type)
			else:
				var error = response.get("error", "Purchase failed")
				global_ui.show_error_notification(error)
	)
