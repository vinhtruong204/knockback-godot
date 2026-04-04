class_name DailyDiscountItem extends Control

@onready var item_texture: TextureRect = $ItemTexture
@onready var buy_btn: Button = $BuyBtn
@onready var discount_label: Label = $BuyBtn/Discount

func set_shop_item(item: Dictionary) -> void:
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
