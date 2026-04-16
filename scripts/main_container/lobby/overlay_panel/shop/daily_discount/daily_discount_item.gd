class_name DailyDiscountItem extends Control

@onready var item_texture: TextureRect = $ItemTexture
@onready var buy_btn: Button = $BuyBtn
@onready var discount_label: Label = $BuyBtn/Discount

var _item_data: Dictionary
var _is_owned: bool = false
var currency_ui: CurrencyContainer

func set_shop_item(item: Dictionary, owned_ids: Dictionary = {}) -> void:
	_item_data = item
	if not buy_btn:
		return

	var item_id = int(item.get("item_id", 0))
	var item_type = item.get("item_type", "")
	_is_owned = owned_ids.has(item_id)

	match item_type:
		Enums.ItemType.WEAPON:
			ConfigApi.get_weapon(item_id, func(response: Dictionary):
				if response.get("ok", false):
					var image_name = response.get("data", {}).get("image", "")
					if image_name != "":
						item_texture.texture = load("res://assets/game/weapon/static/%s" % image_name)
			)
		Enums.ItemType.CHARACTER:
			ConfigApi.get_character(item_id, func(response: Dictionary):
				if response.get("ok", false):
					var texture_name = response.get("data", {}).get("texture", "")
					if texture_name != "":
						item_texture.texture = load("res://assets/game/player/%s" % texture_name)
			)

	if discount_label:
		discount_label.text = "%d%%" % (item.get("discount", 0) * 100)

	if _is_owned:
		buy_btn.text = "Owned"
		buy_btn.disabled = true
	else:
		var price = item.get("price", 0)
		var discount = item.get("discount", 0)
		var final_price = int(price * (1.0 - discount / 100.0))
		buy_btn.text = str(final_price)
		var currency_type = item.get("currency_type", "")
		if not currency_type.is_empty():
			buy_btn.icon = load("res://assets/lobby/top_bar/currency/%s.png" % currency_type)
		buy_btn.pressed.connect(_on_buy_pressed)

	item_texture.mouse_filter = Control.MOUSE_FILTER_STOP
	item_texture.gui_input.connect(_on_texture_input)


func _on_texture_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_open_detail_panel()


func _open_detail_panel() -> void:
	var item_id = int(_item_data.get("item_id", 0))
	var price = int(_item_data.get("price", 0))
	var currency_type = _item_data.get("currency_type", "")
	var item_type = _item_data.get("item_type", "")
	var discount = _item_data.get("discount", 0.0)
	var global_ui: GlobalUI = get_tree().root.get_node("Main/GlobalUi")
	global_ui.show_item_detail(item_id, item_type, price, currency_type, _do_purchase, _is_owned, discount)


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
