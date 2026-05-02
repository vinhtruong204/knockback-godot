class_name ShopCharacterItem extends Control

@onready var character_texture: TextureRect = $TextureRect
@onready var buy_button: Button = $BuyButton

var _item_data: Dictionary
var _is_owned: bool = false
var currency_ui: CurrencyContainer

func set_shop_item(item: Dictionary, owned_ids: Dictionary = {}) -> void:
	_item_data = item
	var item_id = int(item.get("item_id", 0))
	_is_owned = owned_ids.has(item_id)

	ConfigApi.get_character(item_id, func(response: Dictionary):
		if response.get("ok", false):
			var texture_name = response.get("data", {}).get("texture", "")
			if texture_name != "":
				character_texture.texture = load("res://assets/game/player/%s" % texture_name)
	)

	if _is_owned:
		buy_button.text = "Owned"
		buy_button.disabled = true
	else:
		var price = int(item.get("price", 0))
		var currency_type = item.get("currency_type", "")
		buy_button.text = str(price)
		buy_button.icon = load("res://assets/lobby/top_bar/currency/%s.png" % currency_type)
		buy_button.pressed.connect(_on_buy_pressed)

	character_texture.mouse_filter = Control.MOUSE_FILTER_STOP
	character_texture.gui_input.connect(_on_texture_input)


func _on_texture_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_open_detail_panel()


func _open_detail_panel() -> void:
	var item_id = int(_item_data.get("item_id", 0))
	var price = int(_item_data.get("price", 0))
	var currency_type = _item_data.get("currency_type", "")
	var item_type = _item_data.get("item_type", "")
	var global_ui: GlobalUI = get_tree().root.get_node("Main/GlobalUi")
	global_ui.show_item_detail(item_id, item_type, price, currency_type, _do_purchase, _is_owned)


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
			if response.get("ok", false):
				if currency_ui:
					currency_ui.update_currency()
				global_ui.show_purchase_notification(item_type, price, currency_type)
				_is_owned = true
				buy_button.text = "Owned"
				buy_button.icon = null
			else:
				buy_button.disabled = false
				var error = response.get("error", "Purchase failed")
				global_ui.show_error_notification(error)
	)
