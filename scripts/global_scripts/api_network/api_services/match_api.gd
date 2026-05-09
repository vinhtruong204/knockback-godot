extends Node

var base_url: String:
	get: return ApiManager.host + ":8003/api/v1"

# --- Matches (no cache - real-time) ---

func get_matches(callback: Callable):
	ApiManager.send_request(self, base_url, "/matches",
		HTTPClient.METHOD_GET, {}, true, callback)

func get_match(match_id: String, callback: Callable):
	ApiManager.send_request(self, base_url, "/matches/" + match_id,
		HTTPClient.METHOD_GET, {}, true, callback)

func create_match(data: Dictionary, callback: Callable):
	ApiManager.send_request(self, base_url, "/matches",
		HTTPClient.METHOD_POST, data, true, callback)

func update_match(match_id: String, data: Dictionary, callback: Callable):
	ApiManager.send_request(self, base_url, "/matches/" + match_id,
		HTTPClient.METHOD_PUT, data, true, callback)

# --- Maps (cached) ---

func get_maps(callback: Callable, force_refresh := false):
	var key := "match_config:maps"
	if force_refresh:
		CacheManager.invalidate(key)
	CacheManager.fetch_or_cache(key, CacheManager.TTL_STATIC, "match_config", true,
		func(cb: Callable):
			ApiManager.send_request(self, base_url, "/maps",
				HTTPClient.METHOD_GET, {}, true, cb),
		callback)

func get_map(map_id: int, callback: Callable, force_refresh := false):
	var key := "match_config:maps:%d" % map_id
	if force_refresh:
		CacheManager.invalidate(key)
	CacheManager.fetch_or_cache(key, CacheManager.TTL_STATIC, "match_config", true,
		func(cb: Callable):
			ApiManager.send_request(self, base_url, "/maps/%d" % map_id,
				HTTPClient.METHOD_GET, {}, true, cb),
		callback)

# --- Modes (cached) ---

func get_modes(callback: Callable, force_refresh := false):
	var key := "match_config:modes"
	if force_refresh:
		CacheManager.invalidate(key)
	CacheManager.fetch_or_cache(key, CacheManager.TTL_STATIC, "match_config", true,
		func(cb: Callable):
			ApiManager.send_request(self, base_url, "/modes",
				HTTPClient.METHOD_GET, {}, true, cb),
		callback)

func get_mode(mode_id: int, callback: Callable, force_refresh := false):
	var key := "match_config:modes:%d" % mode_id
	if force_refresh:
		CacheManager.invalidate(key)
	CacheManager.fetch_or_cache(key, CacheManager.TTL_STATIC, "match_config", true,
		func(cb: Callable):
			ApiManager.send_request(self, base_url, "/modes/%d" % mode_id,
				HTTPClient.METHOD_GET, {}, true, cb),
		callback)

# --- Match Players (no cache - real-time) ---

func get_match_players(match_id: String, callback: Callable):
	ApiManager.send_request(self, base_url, "/match-players/?match_id=" + match_id,
		HTTPClient.METHOD_GET, {}, true, callback)

func get_match_player(match_id: String, pid: String, callback: Callable):
	ApiManager.send_request(self, base_url, "/match-players/" + match_id + "/" + pid,
		HTTPClient.METHOD_GET, {}, true, callback)

func add_match_player(data: Dictionary, callback: Callable):
	ApiManager.send_request(self, base_url, "/match-players",
		HTTPClient.METHOD_POST, data, true, callback)

func update_match_player(match_id: String, pid: String, data: Dictionary, callback: Callable):
	ApiManager.send_request(self, base_url, "/match-players/" + match_id + "/" + pid,
		HTTPClient.METHOD_PUT, data, true, callback)

# --- Matchmaking (no cache - real-time) ---

func join_matchmaking(rank_point_or_data: Variant, callback: Callable):
	var payload: Dictionary = {}
	if rank_point_or_data is Dictionary:
		payload = rank_point_or_data.duplicate()
	else:
		payload = {"rank_point": int(rank_point_or_data)}

	ApiManager.send_request(self, base_url, "/matchmaking/join",
		HTTPClient.METHOD_POST, payload, true, callback)

func get_matchmaking_status(callback: Callable):
	ApiManager.send_request(self, base_url, "/matchmaking/status",
		HTTPClient.METHOD_GET, {}, true, callback)

func leave_matchmaking(callback: Callable):
	ApiManager.send_request(self, base_url, "/matchmaking/leave",
		HTTPClient.METHOD_DELETE, {}, true, callback)
