extends Node

var base_url: String:
	get: return ApiManager.host + ":8000/api/v1"

# --- Auth (no cache) ---

func login(id_token: String, callback: Callable):
	ApiManager.send_request(self , base_url, "/auth/google", HTTPClient.METHOD_POST,
		{"id_token": id_token}, false, callback)

func dev_login(dev_name: String = "DevPlayer", device_info: String = "", callback: Callable = Callable()):
	var body := {"name": dev_name}
	if device_info != "":
		body["device_info"] = device_info
	ApiManager.send_request(self , base_url, "/auth/dev-login", HTTPClient.METHOD_POST,
		body, false, callback if callback.is_valid() else func(_r): pass )

func signout(callback: Callable = Callable()):
	ApiManager.send_request(self , base_url, "/auth/signout", HTTPClient.METHOD_POST,
		{"session_token": ApiManager.session_token}, false,
		callback if callback.is_valid() else func(_r): pass )

func refresh_token(callback: Callable):
	ApiManager.send_request(self , base_url, "/auth/refresh", HTTPClient.METHOD_POST,
		{"session_token": ApiManager.session_token}, false, callback)

# --- Players ---

func get_players(callback: Callable, skip := 0, limit := 100):
	ApiManager.send_request(self , base_url, "/players?skip=%d&limit=%d" % [skip, limit],
		HTTPClient.METHOD_GET, {}, true, callback)

func get_player(pid: String, callback: Callable, force_refresh := false):
	var key := "player:profile:" + pid
	if force_refresh:
		CacheManager.invalidate(key)
	CacheManager.fetch_or_cache(key, CacheManager.TTL_SEMI, "player", false,
		func(cb: Callable):
			ApiManager.send_request(self , base_url, "/players/" + pid,
				HTTPClient.METHOD_GET, {}, true, cb),
		callback)

func create_player(data: Dictionary, callback: Callable):
	ApiManager.send_request(self , base_url, "/players",
		HTTPClient.METHOD_POST, data, true, callback)

func update_player(pid: String, data: Dictionary, callback: Callable):
	ApiManager.send_request(self , base_url, "/players/" + pid,
		HTTPClient.METHOD_PUT, data, true,
		func(response: Dictionary):
			if response.ok:
				CacheManager.invalidate("player:profile:" + pid)
			callback.call(response))

func delete_player(pid: String, callback: Callable):
	ApiManager.send_request(self , base_url, "/players/" + pid,
		HTTPClient.METHOD_DELETE, {}, true,
		func(response: Dictionary):
			if response.ok:
				CacheManager.invalidate_player(pid)
			callback.call(response))

# --- Player Stats ---

func get_player_stats(pid: String, callback: Callable, force_refresh := false):
	var key := "player:stats:" + pid
	if force_refresh:
		CacheManager.invalidate(key)
	CacheManager.fetch_or_cache(key, CacheManager.TTL_SEMI, "player", false,
		func(cb: Callable):
			ApiManager.send_request(self , base_url, "/players/" + pid + "/stats",
				HTTPClient.METHOD_GET, {}, true, cb),
		callback)

func get_player_stats_by_mode(pid: String, mode: String, callback: Callable, force_refresh := false):
	var key := "player:stats:" + pid + ":" + mode
	if force_refresh:
		CacheManager.invalidate(key)
	CacheManager.fetch_or_cache(key, CacheManager.TTL_SEMI, "player", false,
		func(cb: Callable):
			ApiManager.send_request(self , base_url, "/players/" + pid + "/stats/" + mode,
				HTTPClient.METHOD_GET, {}, true, cb),
		callback)

func create_player_stats(data: Dictionary, callback: Callable):
	ApiManager.send_request(self , base_url, "/player-stats",
		HTTPClient.METHOD_POST, data, true, callback)

func update_player_stats(pid: String, mode: String, data: Dictionary, callback: Callable):
	ApiManager.send_request(self , base_url, "/players/" + pid + "/stats/" + mode,
		HTTPClient.METHOD_PUT, data, true,
		func(response: Dictionary):
			if response.ok:
				CacheManager.invalidate("player:stats:" + pid)
				CacheManager.invalidate("player:stats:" + pid + ":" + mode)
			callback.call(response))

# --- Player Currency ---

func get_player_currencies(pid: String, callback: Callable, force_refresh := false):
	var key := "player_dynamic:currencies:" + pid
	if force_refresh:
		CacheManager.invalidate(key)
	CacheManager.fetch_or_cache(key, CacheManager.TTL_DYNAMIC, "player_dynamic", false,
		func(cb: Callable):
			ApiManager.send_request(self , base_url, "/player-currencies/" + pid,
				HTTPClient.METHOD_GET, {}, true, cb),
		callback)

func get_player_currency(pid: String, currency_type: String, callback: Callable, force_refresh := false):
	var key := "player_dynamic:currencies:" + pid + ":" + currency_type
	if force_refresh:
		CacheManager.invalidate(key)
	CacheManager.fetch_or_cache(key, CacheManager.TTL_DYNAMIC, "player_dynamic", false,
		func(cb: Callable):
			ApiManager.send_request(self , base_url, "/player-currencies/" + pid + "/" + currency_type,
				HTTPClient.METHOD_GET, {}, true, cb),
		callback)

func add_player_currency(data: Dictionary, callback: Callable):
	ApiManager.send_request(self , base_url, "/player-currencies",
		HTTPClient.METHOD_POST, data, true,
		func(response: Dictionary):
			if response.ok:
				CacheManager.invalidate_category("player_dynamic")
			callback.call(response))

func update_player_currency(pid: String, currency_type: String, data: Dictionary, callback: Callable):
	ApiManager.send_request(self , base_url, "/players/" + pid + "/currencies/" + currency_type,
		HTTPClient.METHOD_PUT, data, true,
		func(response: Dictionary):
			if response.ok:
				CacheManager.invalidate("player_dynamic:currencies:" + pid)
				CacheManager.invalidate("player_dynamic:currencies:" + pid + ":" + currency_type)
			callback.call(response))

# --- Player Inventory ---

func get_player_inventory(pid: String, callback: Callable, force_refresh := false):
	var key := "player_dynamic:inventory:" + pid
	if force_refresh:
		CacheManager.invalidate(key)
	CacheManager.fetch_or_cache(key, CacheManager.TTL_DYNAMIC, "player_dynamic", false,
		func(cb: Callable):
			ApiManager.send_request(self , base_url, "/players/" + pid + "/inventory",
				HTTPClient.METHOD_GET, {}, true, cb),
		callback)

func get_inventory_item(pid: String, item_id: String, item_type: String, callback: Callable):
	ApiManager.send_request(self , base_url, "/players/" + pid + "/inventory/" + item_id + "?item_type=" + item_type,
		HTTPClient.METHOD_GET, {}, true, callback)

func add_inventory_item(data: Dictionary, callback: Callable):
	ApiManager.send_request(self , base_url, "/player-inventory",
		HTTPClient.METHOD_POST, data, true,
		func(response: Dictionary):
			if response.ok:
				CacheManager.invalidate_category("player_dynamic")
			callback.call(response))

func update_inventory_item(pid: String, item_id: String, item_type: String, data: Dictionary, callback: Callable):
	ApiManager.send_request(self , base_url, "/players/" + pid + "/inventory/" + item_id + "?item_type=" + item_type,
		HTTPClient.METHOD_PUT, data, true,
		func(response: Dictionary):
			if response.ok:
				CacheManager.invalidate("player_dynamic:inventory:" + pid)
			callback.call(response))

# --- Player Equipment ---

func get_player_equipment(pid: String, callback: Callable, force_refresh := false):
	var key := "player_dynamic:equipment:" + pid
	if force_refresh:
		CacheManager.invalidate(key)
	CacheManager.fetch_or_cache(key, CacheManager.TTL_DYNAMIC, "player_dynamic", false,
		func(cb: Callable):
			ApiManager.send_request(self , base_url, "/players/" + pid + "/equipment",
				HTTPClient.METHOD_GET, {}, true, cb),
		callback)

func get_equipment_slot(pid: String, slot_type: String, callback: Callable, force_refresh := false):
	var key := "player_dynamic:equipment:" + pid + ":" + slot_type
	if force_refresh:
		CacheManager.invalidate(key)
	CacheManager.fetch_or_cache(key, CacheManager.TTL_DYNAMIC, "player_dynamic", false,
		func(cb: Callable):
			ApiManager.send_request(self , base_url, "/players/" + pid + "/equipment/" + slot_type,
				HTTPClient.METHOD_GET, {}, true, cb),
		callback)

func equip_item(data: Dictionary, callback: Callable):
	ApiManager.send_request(self , base_url, "/player-equipment",
		HTTPClient.METHOD_POST, data, true,
		func(response: Dictionary):
			if response.ok:
				CacheManager.invalidate_category("player_dynamic")
			callback.call(response))

func update_equipment(pid: String, slot_type: String, data: Dictionary, callback: Callable):
	ApiManager.send_request(self , base_url, "/players/" + pid + "/equipment/" + slot_type,
		HTTPClient.METHOD_PUT, data, true,
		func(response: Dictionary):
			if response.ok:
				CacheManager.invalidate("player_dynamic:equipment:" + pid)
				CacheManager.invalidate("player_dynamic:equipment:" + pid + ":" + slot_type)
			callback.call(response))

func unequip_item(pid: String, slot_type: String, callback: Callable):
	ApiManager.send_request(self , base_url, "/players/" + pid + "/equipment/" + slot_type,
		HTTPClient.METHOD_DELETE, {}, true,
		func(response: Dictionary):
			if response.ok:
				CacheManager.invalidate("player_dynamic:equipment:" + pid)
				CacheManager.invalidate("player_dynamic:equipment:" + pid + ":" + slot_type)
			callback.call(response))

# --- Selected Character ---

func get_selected_character(pid: String, callback: Callable, force_refresh := false):
	var key := "player_dynamic:selected_char:" + pid
	if force_refresh:
		CacheManager.invalidate(key)
	CacheManager.fetch_or_cache(key, CacheManager.TTL_DYNAMIC, "player_dynamic", false,
		func(cb: Callable):
			ApiManager.send_request(self , base_url, "/players/" + pid + "/selected-character",
				HTTPClient.METHOD_GET, {}, true, cb),
		callback)

func select_character(data: Dictionary, callback: Callable):
	ApiManager.send_request(self , base_url, "/selected-characters",
		HTTPClient.METHOD_POST, data, true,
		func(response: Dictionary):
			if response.ok:
				var pid: String = data.get("player_id", ApiManager.player_id)
				CacheManager.invalidate("player_dynamic:selected_char:" + pid)
			callback.call(response))

func update_selected_character(pid: String, data: Dictionary, callback: Callable):
	ApiManager.send_request(self , base_url, "/players/" + pid + "/selected-character",
		HTTPClient.METHOD_PUT, data, true,
		func(response: Dictionary):
			if response.ok:
				CacheManager.invalidate("player_dynamic:selected_char:" + pid)
			callback.call(response))

# --- Achievements ---

func get_player_achievements(pid: String, callback: Callable, force_refresh := false):
	var key := "player:achievements:" + pid
	if force_refresh:
		CacheManager.invalidate(key)
	CacheManager.fetch_or_cache(key, CacheManager.TTL_SEMI, "player", false,
		func(cb: Callable):
			ApiManager.send_request(self , base_url, "/players/" + pid + "/achievements",
				HTTPClient.METHOD_GET, {}, true, cb),
		callback)

func get_player_achievement(pid: String, achievement_id: String, callback: Callable):
	ApiManager.send_request(self , base_url, "/players/" + pid + "/achievements/" + achievement_id,
		HTTPClient.METHOD_GET, {}, true, callback)

func award_achievement(data: Dictionary, callback: Callable):
	ApiManager.send_request(self , base_url, "/player-achievements",
		HTTPClient.METHOD_POST, data, true,
		func(response: Dictionary):
			if response.ok:
				var pid: String = data.get("player_id", ApiManager.player_id)
				CacheManager.invalidate("player:achievements:" + pid)
			callback.call(response))

func update_achievement_progress(pid: String, achievement_id: String, data: Dictionary, callback: Callable):
	ApiManager.send_request(self , base_url, "/players/" + pid + "/achievements/" + achievement_id,
		HTTPClient.METHOD_PUT, data, true,
		func(response: Dictionary):
			if response.ok:
				CacheManager.invalidate("player:achievements:" + pid)
			callback.call(response))

# --- Ranks ---

func get_player_ranks(pid: String, callback: Callable, force_refresh := false):
	var key := "player:ranks:" + pid
	if force_refresh:
		CacheManager.invalidate(key)
	CacheManager.fetch_or_cache(key, CacheManager.TTL_SEMI, "player", false,
		func(cb: Callable):
			ApiManager.send_request(self , base_url, "/players/" + pid + "/ranks",
				HTTPClient.METHOD_GET, {}, true, cb),
		callback)

func get_player_rank(pid: String, season_id: String, callback: Callable):
	ApiManager.send_request(self , base_url, "/players/" + pid + "/ranks/" + season_id,
		HTTPClient.METHOD_GET, {}, true, callback)

func create_player_rank(data: Dictionary, callback: Callable):
	ApiManager.send_request(self , base_url, "/player-ranks",
		HTTPClient.METHOD_POST, data, true, callback)

func update_player_rank(pid: String, season_id: String, data: Dictionary, callback: Callable):
	ApiManager.send_request(self , base_url, "/players/" + pid + "/ranks/" + season_id,
		HTTPClient.METHOD_PUT, data, true,
		func(response: Dictionary):
			if response.ok:
				CacheManager.invalidate("player:ranks:" + pid)
			callback.call(response))
