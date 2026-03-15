extends Node

var base_url: String:
	get: return ApiManager.host + ":8003/api/v1"

# --- Matches ---

func get_matches(callback: Callable):
	ApiManager.send_request(self , base_url, "/matches",
		HTTPClient.METHOD_GET, {}, true, callback)

func get_match(match_id: String, callback: Callable):
	ApiManager.send_request(self , base_url, "/matches/" + match_id,
		HTTPClient.METHOD_GET, {}, true, callback)

func create_match(data: Dictionary, callback: Callable):
	ApiManager.send_request(self , base_url, "/matches",
		HTTPClient.METHOD_POST, data, true, callback)

# --- Maps ---

func get_maps(callback: Callable):
	ApiManager.send_request(self , base_url, "/maps",
		HTTPClient.METHOD_GET, {}, true, callback)

func get_map(map_id: int, callback: Callable):
	ApiManager.send_request(self , base_url, "/maps/%d" % map_id,
		HTTPClient.METHOD_GET, {}, true, callback)

# --- Modes ---

func get_modes(callback: Callable):
	ApiManager.send_request(self , base_url, "/modes",
		HTTPClient.METHOD_GET, {}, true, callback)

func get_mode(mode_id: int, callback: Callable):
	ApiManager.send_request(self , base_url, "/modes/%d" % mode_id,
		HTTPClient.METHOD_GET, {}, true, callback)

# --- Match Players ---

func get_match_players(match_id: String, callback: Callable):
	ApiManager.send_request(self , base_url, "/matches/" + match_id + "/players",
		HTTPClient.METHOD_GET, {}, true, callback)

func get_match_player(match_id: String, pid: String, callback: Callable):
	ApiManager.send_request(self , base_url, "/matches/" + match_id + "/players/" + pid,
		HTTPClient.METHOD_GET, {}, true, callback)

func add_match_player(data: Dictionary, callback: Callable):
	ApiManager.send_request(self , base_url, "/match-players",
		HTTPClient.METHOD_POST, data, true, callback)

func update_match_player(match_id: String, pid: String, data: Dictionary, callback: Callable):
	ApiManager.send_request(self , base_url, "/matches/" + match_id + "/players/" + pid,
		HTTPClient.METHOD_PUT, data, true, callback)
