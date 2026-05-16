class_name MatchModels


class MapModel:
	var map_id: int
	var name: String
	var image: String

	static func from_dict(data: Dictionary) -> MapModel:
		var model := MapModel.new()
		model.map_id = data.get("map_id", 0)
		model.name = data.get("name", "")
		model.image = data.get("image", "")
		return model

	static func from_array(arr: Array) -> Array[MapModel]:
		var models: Array[MapModel] = []
		for item in arr:
			models.append(MapModel.from_dict(item))
		return models

	func to_dict() -> Dictionary:
		return {
			"map_id": map_id,
			"name": name,
			"image": image,
		}


class ModeModel:
	var mode_id: int
	var name: String
	var type: String
	var code: String
	var players_per_team: int
	var selection_weight: int

	static func from_dict(data: Dictionary) -> ModeModel:
		var model := ModeModel.new()
		model.mode_id = data.get("mode_id", 0)
		model.name = data.get("name", "")
		model.type = data.get("type", "")
		var raw_code = data.get("code", "")
		model.code = "" if raw_code == null else str(raw_code)
		model.players_per_team = data.get("players_per_team", 1)
		var raw_selection_weight = data.get("selection_weight", 0)
		model.selection_weight = 0 if raw_selection_weight == null else int(raw_selection_weight)
		return model

	static func from_array(arr: Array) -> Array[ModeModel]:
		var models: Array[ModeModel] = []
		for item in arr:
			models.append(ModeModel.from_dict(item))
		return models

	func to_dict() -> Dictionary:
		return {
			"mode_id": mode_id,
			"name": name,
			"type": type,
			"code": code,
			"players_per_team": players_per_team,
			"selection_weight": selection_weight,
		}


class MatchHistoryModel:
	var match_id: int
	var map_id: int
	var mode_id: int
	var start_time: String
	var end_time: String
	var status: String  # Enums.MatchStatus
	var season_id: int

	static func from_dict(data: Dictionary) -> MatchHistoryModel:
		var model := MatchHistoryModel.new()
		model.match_id = data.get("match_id", 0)
		model.map_id = data.get("map_id", 0)
		model.mode_id = data.get("mode_id", 0)
		model.start_time = data.get("start_time", "")
		model.end_time = str(data.get("end_time", ""))
		model.status = data.get("status", "")
		model.season_id = data.get("season_id", 0)
		return model

	static func from_array(arr: Array) -> Array[MatchHistoryModel]:
		var models: Array[MatchHistoryModel] = []
		for item in arr:
			models.append(MatchHistoryModel.from_dict(item))
		return models

	func to_dict() -> Dictionary:
		return {
			"match_id": match_id,
			"map_id": map_id,
			"mode_id": mode_id,
			"start_time": start_time,
			"end_time": end_time,
			"status": status,
			"season_id": season_id,
		}


class MatchPlayerModel:
	var match_id: int
	var player_id: String
	var team_id: int
	var kill: int
	var dead: int
	var assists: int
	var result: String  # Enums.MatchResult
	var score: int
	var exp_earned: int
	var reward_gold: int

	static func from_dict(data: Dictionary) -> MatchPlayerModel:
		var model := MatchPlayerModel.new()
		model.match_id = data.get("match_id", 0)
		model.player_id = data.get("player_id", "")
		model.team_id = data.get("team_id", 0)
		model.kill = data.get("kill", 0)
		model.dead = data.get("dead", 0)
		model.assists = data.get("assists", 0)
		model.result = data.get("result", "")
		model.score = data.get("score", 0)
		model.exp_earned = data.get("exp_earned", 0)
		model.reward_gold = data.get("reward_gold", 0)
		return model

	static func from_array(arr: Array) -> Array[MatchPlayerModel]:
		var models: Array[MatchPlayerModel] = []
		for item in arr:
			models.append(MatchPlayerModel.from_dict(item))
		return models

	func to_dict() -> Dictionary:
		return {
			"match_id": match_id,
			"player_id": player_id,
			"team_id": team_id,
			"kill": kill,
			"dead": dead,
			"assists": assists,
			"result": result,
			"score": score,
			"exp_earned": exp_earned,
			"reward_gold": reward_gold,
		}


class MatchmakingPlayerInfo:
	var player_id: String
	var team_id: int

	static func from_dict(data: Dictionary) -> MatchmakingPlayerInfo:
		var model := MatchmakingPlayerInfo.new()
		model.player_id = data.get("player_id", "")
		model.team_id = data.get("team_id", 0)
		return model

	static func from_array(arr: Array) -> Array[MatchmakingPlayerInfo]:
		var models: Array[MatchmakingPlayerInfo] = []
		for item in arr:
			models.append(MatchmakingPlayerInfo.from_dict(item))
		return models

	func to_dict() -> Dictionary:
		return {
			"player_id": player_id,
			"team_id": team_id,
		}


class MatchmakingQueuedModel:
	var status: String  # "queued"
	var queue_id: int
	var player_id: String
	var position: int
	var joined_at: String

	static func from_dict(data: Dictionary) -> MatchmakingQueuedModel:
		var model := MatchmakingQueuedModel.new()
		model.status = data.get("status", "queued")
		model.queue_id = data.get("queue_id", 0)
		model.player_id = data.get("player_id", "")
		model.position = data.get("position", 0)
		model.joined_at = data.get("joined_at", "")
		return model

	func to_dict() -> Dictionary:
		return {
			"status": status,
			"queue_id": queue_id,
			"player_id": player_id,
			"position": position,
			"joined_at": joined_at,
		}


class MatchmakingMatchFoundModel:
	var status: String  # "match_found"
	var match_id: int
	var mode_id: int
	var mode_name: String
	var mode_code: String
	var map_id: int
	var map_name: String
	var players_per_team: int
	var players: Array[MatchmakingPlayerInfo]

	static func from_dict(data: Dictionary) -> MatchmakingMatchFoundModel:
		var model := MatchmakingMatchFoundModel.new()
		model.status = data.get("status", "match_found")
		model.match_id = data.get("match_id", 0)
		model.mode_id = data.get("mode_id", 0)
		model.mode_name = data.get("mode_name", "")
		var raw_mode_code = data.get("mode_code", "")
		model.mode_code = "" if raw_mode_code == null else str(raw_mode_code)
		model.map_id = data.get("map_id", 0)
		model.map_name = data.get("map_name", "")
		model.players_per_team = data.get("players_per_team", 1)
		model.players = MatchmakingPlayerInfo.from_array(data.get("players", []))
		return model

	func to_dict() -> Dictionary:
		var players_arr: Array[Dictionary] = []
		for p in players:
			players_arr.append(p.to_dict())
		return {
			"status": status,
			"match_id": match_id,
			"mode_id": mode_id,
			"mode_name": mode_name,
			"mode_code": mode_code,
			"map_id": map_id,
			"map_name": map_name,
			"players_per_team": players_per_team,
			"players": players_arr,
		}


class MatchmakingWaitingModel:
	var status: String  # "waiting"
	var queue_id: int
	var position: int
	var wait_seconds: float
	var joined_at: String

	static func from_dict(data: Dictionary) -> MatchmakingWaitingModel:
		var model := MatchmakingWaitingModel.new()
		model.status = data.get("status", "waiting")
		model.queue_id = data.get("queue_id", 0)
		model.position = data.get("position", 0)
		model.wait_seconds = data.get("wait_seconds", 0.0)
		model.joined_at = data.get("joined_at", "")
		return model

	func to_dict() -> Dictionary:
		return {
			"status": status,
			"queue_id": queue_id,
			"position": position,
			"wait_seconds": wait_seconds,
			"joined_at": joined_at,
		}


class MatchmakingMatchedModel:
	var status: String  # "matched"
	var match_id: int
	var mode_id: int
	var mode_name: String
	var mode_code: String
	var map_id: int
	var map_name: String
	var players_per_team: int
	var players: Array[MatchmakingPlayerInfo]

	static func from_dict(data: Dictionary) -> MatchmakingMatchedModel:
		var model := MatchmakingMatchedModel.new()
		model.status = data.get("status", "matched")
		model.match_id = data.get("match_id", 0)
		model.mode_id = data.get("mode_id", 0)
		model.mode_name = data.get("mode_name", "")
		var raw_mode_code = data.get("mode_code", "")
		model.mode_code = "" if raw_mode_code == null else str(raw_mode_code)
		model.map_id = data.get("map_id", 0)
		model.map_name = data.get("map_name", "")
		model.players_per_team = data.get("players_per_team", 1)
		model.players = MatchmakingPlayerInfo.from_array(data.get("players", []))
		return model

	func to_dict() -> Dictionary:
		var players_arr: Array[Dictionary] = []
		for p in players:
			players_arr.append(p.to_dict())
		return {
			"status": status,
			"match_id": match_id,
			"mode_id": mode_id,
			"mode_name": mode_name,
			"mode_code": mode_code,
			"map_id": map_id,
			"map_name": map_name,
			"players_per_team": players_per_team,
			"players": players_arr,
		}


class MatchmakingNoneModel:
	var status: String  # "none"

	static func from_dict(data: Dictionary) -> MatchmakingNoneModel:
		var model := MatchmakingNoneModel.new()
		model.status = data.get("status", "none")
		return model

	func to_dict() -> Dictionary:
		return {"status": status}


class MatchmakingLeftModel:
	var status: String  # "left"
	var player_id: String

	static func from_dict(data: Dictionary) -> MatchmakingLeftModel:
		var model := MatchmakingLeftModel.new()
		model.status = data.get("status", "left")
		model.player_id = data.get("player_id", "")
		return model

	func to_dict() -> Dictionary:
		return {
			"status": status,
			"player_id": player_id,
		}


## Utility to parse any matchmaking response by status field
static func parse_matchmaking_response(data: Dictionary) -> Variant:
	var status: String = data.get("status", "")
	match status:
		"queued":
			return MatchmakingQueuedModel.from_dict(data)
		"match_found":
			return MatchmakingMatchFoundModel.from_dict(data)
		"waiting":
			return MatchmakingWaitingModel.from_dict(data)
		"matched":
			return MatchmakingMatchedModel.from_dict(data)
		"none":
			return MatchmakingNoneModel.from_dict(data)
		"left":
			return MatchmakingLeftModel.from_dict(data)
		_:
			return null
