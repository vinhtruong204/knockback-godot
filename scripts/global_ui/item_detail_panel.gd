class_name ItemDetailPanel extends PanelContainer

@onready var item_preview: TextureRect = $MarginContainer/HBoxContainer/ItemPreview
@onready var name_label: Label = $MarginContainer/HBoxContainer/InfoColumn/NameLabel
@onready var properties_grid: GridContainer = $MarginContainer/HBoxContainer/InfoColumn/PropertiesGrid
@onready var currency_icon: TextureRect = $MarginContainer/HBoxContainer/InfoColumn/PriceRow/CurrencyIcon
@onready var price_label: Label = $MarginContainer/HBoxContainer/InfoColumn/PriceRow/PriceLabel
@onready var buy_button: Button = $MarginContainer/HBoxContainer/InfoColumn/ButtonRow/BuyButton
@onready var cancel_button: Button = $MarginContainer/HBoxContainer/InfoColumn/ButtonRow/CancelButton

var _on_buy: Callable


func _ready() -> void:
	buy_button.pressed.connect(_on_buy_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)


func show_detail(item_id: int, item_type: String, price: int, currency_type: String, on_buy: Callable, is_owned: bool, discount: float = 0.0) -> void:
	_on_buy = on_buy
	_clear_properties()

	# Price display
	var final_price := price
	if discount > 0:
		final_price = int(price * (1.0 - discount / 100.0))
	price_label.text = str(final_price)
	if currency_type != "":
		currency_icon.texture = load("res://assets/lobby/top_bar/currency/%s.png" % currency_type)

	# Owned state
	if is_owned:
		buy_button.text = tr("COMMON_OWNED")
		buy_button.disabled = true
	else:
		buy_button.text = tr("COMMON_BUY")
		buy_button.disabled = false

	# Fetch config and populate
	match item_type:
		Enums.ItemType.WEAPON:
			ConfigApi.get_weapon(item_id, func(response: Dictionary):
				if response.get("ok", false):
					var data = response.get("data", {})
					name_label.text = data.get("name", tr("COMMON_UNKNOWN"))
					var image_name = data.get("image", "")
					if image_name != "":
						item_preview.texture = load("res://assets/game/weapon/static/%s" % image_name)
					_add_property(tr("ITEM_PROP_TYPE"), data.get("weapon_type", "").capitalize())
					_add_property(tr("ITEM_PROP_DAMAGE"), str(data.get("damage", 0)))
					_add_property(tr("ITEM_PROP_FIRE_RATE"), str(data.get("fire_rate", 0.0)))
			)
		Enums.ItemType.CHARACTER:
			ConfigApi.get_character(item_id, func(response: Dictionary):
				if response.get("ok", false):
					var data = response.get("data", {})
					name_label.text = data.get("name", tr("COMMON_UNKNOWN"))
					var texture_name = data.get("texture", "")
					if texture_name != "":
						item_preview.texture = load("res://assets/game/player/%s" % texture_name)
					_add_property(tr("ITEM_PROP_TYPE"), data.get("character_type", "").capitalize())
					_add_property(tr("ITEM_PROP_HP"), str(data.get("hp", 0)))
					_add_property(tr("ITEM_PROP_RUN_SPEED"), str(data.get("run_speed", 0.0)))
			)
		_:
			name_label.text = item_type.capitalize()


func _add_property(prop_name: String, prop_value: String) -> void:
	var name_lbl := Label.new()
	name_lbl.text = prop_name + ":"
	properties_grid.add_child(name_lbl)
	var value_lbl := Label.new()
	value_lbl.text = prop_value
	properties_grid.add_child(value_lbl)


func _clear_properties() -> void:
	for child in properties_grid.get_children():
		child.free()


func _on_buy_pressed() -> void:
	get_parent().visible = false
	if _on_buy.is_valid():
		_on_buy.call()


func _on_cancel_pressed() -> void:
	get_parent().visible = false
