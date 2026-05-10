class_name ShopRecommendedCombo extends Panel

# The 3 weapons that make up the combo bundle. Order = visual left → right.
const RECOMMENDED_WEAPON_IDS: Array[int] = [51, 55, 67]

# All combo prices are quoted and paid in gold. Diamond-priced items in the
# trio get converted at this rate when summing the total.
const DIAMOND_TO_GOLD: int = 100

@onready var slots: Array[VBoxContainer] = [
	$VBoxContainer/HBoxContainer/Slot1,
	$VBoxContainer/HBoxContainer/Slot2,
	$VBoxContainer/HBoxContainer/Slot3,
]
@onready var buy_btn: Button = $VBoxContainer/BuyBtn

var _shop_items: Array[Dictionary] = [{}, {}, {}]
var _owned: Array[bool] = [false, false, false]
var _total_gold: int = 0
var _purchasing: bool = false


func _ready() -> void:
	buy_btn.pressed.connect(_on_buy_pressed)
	_refresh()


func _refresh() -> void:
	var pid := ApiManager.player_id
	PlayerApi.get_inventory_by_type(pid, Enums.ItemType.WEAPON, func(inv_response: Dictionary) -> void:
		var owned_ids := {}
		if inv_response.get("ok", false):
			for inv_item in inv_response.get("data", []):
				owned_ids[int(inv_item.get("item_id", 0))] = true
		_load_shop_items(owned_ids)
	)


func _load_shop_items(owned_ids: Dictionary) -> void:
	EconomyApi.get_shop_items(func(response: Dictionary) -> void:
		if not response.get("ok", false):
			push_warning("[ShopRecommendedCombo] Failed to load shop items")
			return
		var by_id := {}
		for item in response.get("data", []):
			by_id[int(item.get("item_id", 0))] = item
		for i in range(3):
			var wid: int = RECOMMENDED_WEAPON_IDS[i]
			var item: Dictionary = by_id.get(wid, {})
			if item.is_empty():
				push_warning("[ShopRecommendedCombo] Weapon id %d not in shop" % wid)
			_shop_items[i] = item
			_owned[i] = owned_ids.has(int(item.get("item_id", -1)))
		_render_slots()
		_update_buy_button()
	, Enums.ItemType.WEAPON)


func _render_slots() -> void:
	for i in range(3):
		var slot := slots[i]
		var tex_rect: TextureRect = slot.get_node("TextureRect")
		var owned_label: Label = slot.get_node("OwnedLabel")
		var item: Dictionary = _shop_items[i]
		owned_label.visible = _owned[i]
		tex_rect.modulate = Color(0.5, 0.5, 0.5) if _owned[i] else Color.WHITE
		if item.is_empty():
			tex_rect.texture = null
			continue
		var item_id := int(item.get("item_id", 0))
		ConfigApi.get_weapon(item_id, func(response: Dictionary) -> void:
			if response.get("ok", false):
				var image_name: String = response.get("data", {}).get("image", "")
				if image_name != "":
					tex_rect.texture = load("res://assets/game/weapon/static/%s" % image_name)
		)


func _compute_total_gold(only_unowned: bool) -> int:
	var total := 0
	for i in range(3):
		if only_unowned and _owned[i]:
			continue
		var item: Dictionary = _shop_items[i]
		if item.is_empty():
			continue
		var price := int(item.get("price", 0))
		var currency_type: String = item.get("currency_type", "gold")
		if currency_type == "diamond":
			total += price * DIAMOND_TO_GOLD
		else:
			total += price
	return total


func _update_buy_button() -> void:
	var all_owned := _owned[0] and _owned[1] and _owned[2]
	if all_owned:
		buy_btn.text = "Owned"
		buy_btn.icon = null
		buy_btn.disabled = true
		return
	_total_gold = _compute_total_gold(true)
	buy_btn.text = str(_total_gold)
	buy_btn.icon = load("res://assets/lobby/top_bar/currency/gold.png")
	buy_btn.disabled = _purchasing


func _on_buy_pressed() -> void:
	if _purchasing:
		return
	var global_ui: GlobalUI = get_tree().root.get_node("Main/GlobalUi")
	global_ui.show_confirm_purchase("Combo Bundle", _total_gold, "gold", _do_purchase)


func _do_purchase() -> void:
	_purchasing = true
	buy_btn.disabled = true
	var queue: Array[int] = []
	for i in range(3):
		if not _owned[i] and not _shop_items[i].is_empty():
			queue.append(i)
	if queue.is_empty():
		_purchasing = false
		_update_buy_button()
		return
	_purchase_next(queue, 0)


func _purchase_next(queue: Array[int], cursor: int) -> void:
	var global_ui: GlobalUI = get_tree().root.get_node("Main/GlobalUi")
	var currency_ui: CurrencyContainer = %UIButtons/TopBar/CurrencyContainer
	if cursor >= queue.size():
		# All purchases succeeded. Refresh balance + notify.
		currency_ui.update_currency()
		global_ui.show_purchase_notification("Combo Bundle", _total_gold, "gold")
		_purchasing = false
		_update_buy_button()
		return
	var slot_idx: int = queue[cursor]
	var item: Dictionary = _shop_items[slot_idx]
	# Force everything to gold: send currency_type="gold" and converted price,
	# regardless of the item's native currency_type. Backend trusts client price.
	var native_price := int(item.get("price", 0))
	var native_currency: String = item.get("currency_type", "gold")
	var gold_price := native_price * DIAMOND_TO_GOLD if native_currency == "diamond" else native_price
	PlayerApi.purchase_item(
		{
			"item_id": int(item.get("item_id", 0)),
			"item_type": item.get("item_type", "weapon"),
			"currency_type": "gold",
			"price": gold_price,
		},
		func(response: Dictionary) -> void:
			if response.get("ok", false):
				_owned[slot_idx] = true
				_render_slots()
				_purchase_next(queue, cursor + 1)
			else:
				var err: String = response.get("error", "Purchase failed")
				global_ui.show_error_notification(err)
				_purchasing = false
				# Refresh balance after partial spend.
				currency_ui.update_currency()
				_update_buy_button()
	)
