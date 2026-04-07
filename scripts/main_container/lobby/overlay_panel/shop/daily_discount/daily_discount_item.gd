class_name DailyDiscountItem extends Control

@onready var item_texture: TextureRect = $ItemTexture
@onready var buy_btn: Button = $BuyBtn
@onready var discount_label: Label = $BuyBtn/Discount

var _item_data: Dictionary
var currency_ui: CurrencyContainer

func set_shop_item(item: Dictionary) -> void:
	_item_data = item
	if not buy_btn:
		return

	if discount_label:
		discount_label.text = "%d%%" % (item.get("discount", 0) * 100)

	var price = item.get("price", 0)
	var discount = item.get("discount", 0)
	var final_price = int(price * (1.0 - discount / 100.0))

	buy_btn.text = str(final_price)
	var currency_type = item.get("currency_type", "")
	if not currency_type.is_empty():
		buy_btn.icon = load("res://assets/lobby/top_bar/currency/%s.png" % currency_type)
	buy_btn.pressed.connect(_on_buy_pressed)


func _get_final_price() -> int:
	var price = _item_data.get("price", 0)
	var discount = _item_data.get("discount", 0)
	return int(price * (1.0 - discount / 100.0))


func _on_buy_pressed() -> void:
	var final_price = _get_final_price()
	var currency_type = _item_data.get("currency_type", "")
	var item_type = _item_data.get("item_type", "")
	var global_ui: GlobalUI = get_tree().root.get_node("Main/GlobalUi")

	global_ui.show_confirm_purchase(item_type, final_price, currency_type, _do_purchase)


func _do_purchase() -> void:
	buy_btn.disabled = true
	var final_price = _get_final_price()
	var currency_type = _item_data.get("currency_type", "")
	var item_id = int(_item_data.get("item_id", 0))
	var item_type = _item_data.get("item_type", "")
	var global_ui: GlobalUI = get_tree().root.get_node("Main/GlobalUi")

	PlayerApi.purchase_item(
		{"item_id": item_id, "item_type": item_type, "currency_type": currency_type, "price": final_price},
		func(response: Dictionary) -> void:
			buy_btn.disabled = false
			if response.get("ok", false):
				if currency_ui:
					currency_ui.update_currency()
				global_ui.show_purchase_notification(item_type, final_price, currency_type)
			else:
				var error = response.get("error", "Purchase failed")
				global_ui.show_error_notification(error)
	)
