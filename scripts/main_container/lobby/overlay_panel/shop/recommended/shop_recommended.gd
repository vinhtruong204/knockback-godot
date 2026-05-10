class_name ShopRecommended extends Control

# Curated featured weapons. Order = display order (left → right).
# IDs must exist in the economy-service Shop table with item_type=weapon;
# IDs not present are skipped with a warning.
const RECOMMENDED_WEAPON_IDS: Array[int] = [1, 2, 3]

@export var shop_weapon_item: PackedScene
@onready var card_container: HBoxContainer = $HBoxContainer


func _ready() -> void:
	load_recommended()


func load_recommended() -> void:
	var currency_ui: CurrencyContainer = %UIButtons/TopBar/CurrencyContainer
	var pid := ApiManager.player_id
	PlayerApi.get_inventory_by_type(pid, Enums.ItemType.WEAPON, func(inv_response: Dictionary) -> void:
		var owned_ids := {}
		if inv_response.get("ok", false):
			for inv_item in inv_response.get("data", []):
				owned_ids[int(inv_item.get("item_id", 0))] = true
		else:
			print("[ShopRecommended] Inventory fetch failed: ", inv_response.get("error", ""))
		_load_shop_items(currency_ui, owned_ids)
	)


func _load_shop_items(currency_ui: CurrencyContainer, owned_ids: Dictionary) -> void:
	EconomyApi.get_shop_items(func(response: Dictionary) -> void:
		if not response.get("ok", false):
			push_warning("[ShopRecommended] Failed to load shop items")
			return
		var by_id := {}
		for item in response.get("data", []):
			by_id[int(item.get("item_id", 0))] = item
		for wid in RECOMMENDED_WEAPON_IDS:
			var item: Dictionary = by_id.get(wid, {})
			if item.is_empty():
				push_warning("[ShopRecommended] Weapon id %d not found in shop, skipping" % wid)
				continue
			var card = shop_weapon_item.instantiate()
			card_container.add_child(card)
			card.currency_ui = currency_ui
			card.set_shop_item(item, owned_ids)
	, Enums.ItemType.WEAPON)
