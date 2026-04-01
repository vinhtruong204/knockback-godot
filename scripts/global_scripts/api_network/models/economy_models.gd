class_name EconomyModels


class ShopModel:
	var shop_id: int
	var item_id: int
	var item_type: String  # Enums.ItemType
	var price: int
	var currency_type: String  # Enums.CurrencyType
	var discount: float
	var is_today: bool
	var start_at: String
	var end_at: String

	static func from_dict(data: Dictionary) -> ShopModel:
		var model := ShopModel.new()
		model.shop_id = data.get("shop_id", 0)
		model.item_id = data.get("item_id", 0)
		model.item_type = data.get("item_type", "")
		model.price = data.get("price", 0)
		model.currency_type = data.get("currency_type", "")
		model.discount = data.get("discount", 0.0)
		model.is_today = data.get("is_today", false)
		model.start_at = data.get("start_at", "")
		model.end_at = data.get("end_at", "")
		return model

	static func from_array(arr: Array) -> Array[ShopModel]:
		var models: Array[ShopModel] = []
		for item in arr:
			models.append(ShopModel.from_dict(item))
		return models

	func to_dict() -> Dictionary:
		return {
			"shop_id": shop_id,
			"item_id": item_id,
			"item_type": item_type,
			"price": price,
			"currency_type": currency_type,
			"discount": discount,
			"is_today": is_today,
			"start_at": start_at,
			"end_at": end_at,
		}
