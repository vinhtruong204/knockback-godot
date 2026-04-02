extends Node

var base_url: String:
	get: return ApiManager.host + ":8002/api/v1"

func get_shop_items(callback: Callable, item_type := "", currency_type := "", is_today := false, force_refresh := false):
	var query_parts: Array[String] = []
	if item_type != "":
		query_parts.append("item_type=" + item_type)
	if currency_type != "":
		query_parts.append("currency_type=" + currency_type)
	if is_today:
		query_parts.append("is_today=true")
	var query := "?" + "&".join(query_parts) if not query_parts.is_empty() else ""

	var key := "economy:shop_items" + query
	if force_refresh:
		CacheManager.invalidate(key)
	CacheManager.fetch_or_cache(key, CacheManager.TTL_SEMI, "economy", false,
		func(cb: Callable):
			ApiManager.send_request(self, base_url, "/shop-items" + query,
				HTTPClient.METHOD_GET, {}, true, cb),
		callback)

func get_shop_item(shop_id: int, callback: Callable, force_refresh := false):
	var key := "economy:shop_items:%d" % shop_id
	if force_refresh:
		CacheManager.invalidate(key)
	CacheManager.fetch_or_cache(key, CacheManager.TTL_SEMI, "economy", false,
		func(cb: Callable):
			ApiManager.send_request(self, base_url, "/shop-items/%d" % shop_id,
				HTTPClient.METHOD_GET, {}, true, cb),
		callback)
