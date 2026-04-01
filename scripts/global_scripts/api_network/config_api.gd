extends Node

var base_url: String:
	get: return ApiManager.host + ":8001/api/v1"

# --- Weapons ---

func get_weapons(callback: Callable, skip := 0, limit := 100, force_refresh := false):
	var key := "config:weapons"
	if force_refresh:
		CacheManager.invalidate(key)
	CacheManager.fetch_or_cache(key, CacheManager.TTL_STATIC, "config", true,
		func(cb: Callable):
			ApiManager.send_request(self, base_url, "/weapons?skip=%d&limit=%d" % [skip, limit],
				HTTPClient.METHOD_GET, {}, true, cb),
		callback)

func get_weapon(weapon_id: int, callback: Callable, force_refresh := false):
	var key := "config:weapons:%d" % weapon_id
	if force_refresh:
		CacheManager.invalidate(key)
	CacheManager.fetch_or_cache(key, CacheManager.TTL_STATIC, "config", true,
		func(cb: Callable):
			ApiManager.send_request(self, base_url, "/weapons/%d" % weapon_id,
				HTTPClient.METHOD_GET, {}, true, cb),
		callback)

# --- Characters ---

func get_characters(callback: Callable, skip := 0, limit := 100, force_refresh := false):
	var key := "config:characters"
	if force_refresh:
		CacheManager.invalidate(key)
	CacheManager.fetch_or_cache(key, CacheManager.TTL_STATIC, "config", true,
		func(cb: Callable):
			ApiManager.send_request(self, base_url, "/characters?skip=%d&limit=%d" % [skip, limit],
				HTTPClient.METHOD_GET, {}, true, cb),
		callback)

func get_character(character_id: int, callback: Callable, force_refresh := false):
	var key := "config:characters:%d" % character_id
	if force_refresh:
		CacheManager.invalidate(key)
	CacheManager.fetch_or_cache(key, CacheManager.TTL_STATIC, "config", true,
		func(cb: Callable):
			ApiManager.send_request(self, base_url, "/characters/%d" % character_id,
				HTTPClient.METHOD_GET, {}, true, cb),
		callback)

# --- Achievements ---

func get_achievements(callback: Callable, skip := 0, limit := 100, force_refresh := false):
	var key := "config:achievements"
	if force_refresh:
		CacheManager.invalidate(key)
	CacheManager.fetch_or_cache(key, CacheManager.TTL_STATIC, "config", true,
		func(cb: Callable):
			ApiManager.send_request(self, base_url, "/achievements?skip=%d&limit=%d" % [skip, limit],
				HTTPClient.METHOD_GET, {}, true, cb),
		callback)

func get_achievement(achievement_id: int, callback: Callable, force_refresh := false):
	var key := "config:achievements:%d" % achievement_id
	if force_refresh:
		CacheManager.invalidate(key)
	CacheManager.fetch_or_cache(key, CacheManager.TTL_STATIC, "config", true,
		func(cb: Callable):
			ApiManager.send_request(self, base_url, "/achievements/%d" % achievement_id,
				HTTPClient.METHOD_GET, {}, true, cb),
		callback)

# --- Level Configs ---

func get_level_configs(callback: Callable, skip := 0, limit := 100, force_refresh := false):
	var key := "config:level_configs"
	if force_refresh:
		CacheManager.invalidate(key)
	CacheManager.fetch_or_cache(key, CacheManager.TTL_STATIC, "config", true,
		func(cb: Callable):
			ApiManager.send_request(self, base_url, "/level-configs?skip=%d&limit=%d" % [skip, limit],
				HTTPClient.METHOD_GET, {}, true, cb),
		callback)

func get_level_config(level_id: int, callback: Callable, force_refresh := false):
	var key := "config:level_configs:%d" % level_id
	if force_refresh:
		CacheManager.invalidate(key)
	CacheManager.fetch_or_cache(key, CacheManager.TTL_STATIC, "config", true,
		func(cb: Callable):
			ApiManager.send_request(self, base_url, "/level-configs/%d" % level_id,
				HTTPClient.METHOD_GET, {}, true, cb),
		callback)

# --- Rank Configs ---

func get_rank_configs(callback: Callable, skip := 0, limit := 100, force_refresh := false):
	var key := "config:rank_configs"
	if force_refresh:
		CacheManager.invalidate(key)
	CacheManager.fetch_or_cache(key, CacheManager.TTL_STATIC, "config", true,
		func(cb: Callable):
			ApiManager.send_request(self, base_url, "/rank-configs?skip=%d&limit=%d" % [skip, limit],
				HTTPClient.METHOD_GET, {}, true, cb),
		callback)

func get_rank_config(rank_id: int, callback: Callable, force_refresh := false):
	var key := "config:rank_configs:%d" % rank_id
	if force_refresh:
		CacheManager.invalidate(key)
	CacheManager.fetch_or_cache(key, CacheManager.TTL_STATIC, "config", true,
		func(cb: Callable):
			ApiManager.send_request(self, base_url, "/rank-configs/%d" % rank_id,
				HTTPClient.METHOD_GET, {}, true, cb),
		callback)
