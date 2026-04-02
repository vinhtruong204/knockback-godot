class_name PlayerModels


class AuthResponseModel:
	var session_token: String
	var player_id: String
	var is_new_player: bool

	static func from_dict(data: Dictionary) -> AuthResponseModel:
		var model := AuthResponseModel.new()
		model.session_token = data.get("session_token", "")
		model.player_id = data.get("player_id", "")
		model.is_new_player = data.get("is_new_player", false)
		return model

	func to_dict() -> Dictionary:
		return {
			"session_token": session_token,
			"player_id": player_id,
			"is_new_player": is_new_player,
		}


class RefreshResponseModel:
	var session_token: String
	var expires_at: String

	static func from_dict(data: Dictionary) -> RefreshResponseModel:
		var model := RefreshResponseModel.new()
		model.session_token = data.get("session_token", "")
		model.expires_at = data.get("expires_at", "")
		return model

	func to_dict() -> Dictionary:
		return {
			"session_token": session_token,
			"expires_at": expires_at,
		}


class PlayerProfileModel:
	var player_id: String
	var current_level_id: int
	var name: String
	var slogan: String
	var current_exp: int
	var is_new_player: bool
	var create_at: String
	var last_login_at: String

	static func from_dict(data: Dictionary) -> PlayerProfileModel:
		var model := PlayerProfileModel.new()
		model.player_id = data.get("player_id", "")
		model.current_level_id = data.get("current_level_id", 1)
		model.name = data.get("name", "")
		model.slogan = str(data.get("slogan", ""))
		model.current_exp = data.get("current_exp", 0)
		model.is_new_player = data.get("is_new_player", false)
		model.create_at = data.get("create_at", "")
		model.last_login_at = data.get("last_login_at", "")
		return model

	static func from_array(arr: Array) -> Array[PlayerProfileModel]:
		var models: Array[PlayerProfileModel] = []
		for item in arr:
			models.append(PlayerProfileModel.from_dict(item))
		return models

	func to_dict() -> Dictionary:
		return {
			"player_id": player_id,
			"current_level_id": current_level_id,
			"name": name,
			"slogan": slogan,
			"current_exp": current_exp,
			"is_new_player": is_new_player,
			"create_at": create_at,
			"last_login_at": last_login_at,
		}


class PlayerStatsModel:
	var player_id: String
	var mode: String  # Enums.GameMode
	var current_point: int
	var total_game: int
	var number_games_win: int
	var kill: int
	var dead: int
	var assists: int

	static func from_dict(data: Dictionary) -> PlayerStatsModel:
		var model := PlayerStatsModel.new()
		model.player_id = data.get("player_id", "")
		model.mode = data.get("mode", "")
		model.current_point = data.get("current_point", 0)
		model.total_game = data.get("total_game", 0)
		model.number_games_win = data.get("number_games_win", 0)
		model.kill = data.get("kill", 0)
		model.dead = data.get("dead", 0)
		model.assists = data.get("assists", 0)
		return model

	static func from_array(arr: Array) -> Array[PlayerStatsModel]:
		var models: Array[PlayerStatsModel] = []
		for item in arr:
			models.append(PlayerStatsModel.from_dict(item))
		return models

	func to_dict() -> Dictionary:
		return {
			"player_id": player_id,
			"mode": mode,
			"current_point": current_point,
			"total_game": total_game,
			"number_games_win": number_games_win,
			"kill": kill,
			"dead": dead,
			"assists": assists,
		}


class PlayerCurrencyModel:
	var player_id: String
	var currency_type: String  # Enums.CurrencyType
	var amount: int

	static func from_dict(data: Dictionary) -> PlayerCurrencyModel:
		var model := PlayerCurrencyModel.new()
		model.player_id = data.get("player_id", "")
		model.currency_type = data.get("currency_type", "")
		model.amount = data.get("amount", 0)
		return model

	static func from_array(arr: Array) -> Array[PlayerCurrencyModel]:
		var models: Array[PlayerCurrencyModel] = []
		for item in arr:
			models.append(PlayerCurrencyModel.from_dict(item))
		return models

	func to_dict() -> Dictionary:
		return {
			"player_id": player_id,
			"currency_type": currency_type,
			"amount": amount,
		}


class CurrencyModifyModel:
	var amount: int

	static func from_dict(data: Dictionary) -> CurrencyModifyModel:
		var model := CurrencyModifyModel.new()
		model.amount = data.get("amount", 0)
		return model

	func to_dict() -> Dictionary:
		return {
			"amount": amount,
		}


class PlayerInventoryModel:
	var player_id: String
	var item_id: int
	var item_type: String  # Enums.ItemType
	var quantity: int
	var obtain_at: String

	static func from_dict(data: Dictionary) -> PlayerInventoryModel:
		var model := PlayerInventoryModel.new()
		model.player_id = data.get("player_id", "")
		model.item_id = data.get("item_id", 0)
		model.item_type = data.get("item_type", "")
		model.quantity = data.get("quantity", 1)
		model.obtain_at = data.get("obtain_at", "")
		return model

	static func from_array(arr: Array) -> Array[PlayerInventoryModel]:
		var models: Array[PlayerInventoryModel] = []
		for item in arr:
			models.append(PlayerInventoryModel.from_dict(item))
		return models

	func to_dict() -> Dictionary:
		return {
			"player_id": player_id,
			"item_id": item_id,
			"item_type": item_type,
			"quantity": quantity,
			"obtain_at": obtain_at,
		}


class PlayerEquipmentModel:
	var player_id: String
	var slot_type: String  # Enums.SlotType
	var weapon_id: int

	static func from_dict(data: Dictionary) -> PlayerEquipmentModel:
		var model := PlayerEquipmentModel.new()
		model.player_id = data.get("player_id", "")
		model.slot_type = data.get("slot_type", "")
		model.weapon_id = data.get("weapon_id", 0)
		return model

	static func from_array(arr: Array) -> Array[PlayerEquipmentModel]:
		var models: Array[PlayerEquipmentModel] = []
		for item in arr:
			models.append(PlayerEquipmentModel.from_dict(item))
		return models

	func to_dict() -> Dictionary:
		return {
			"player_id": player_id,
			"slot_type": slot_type,
			"weapon_id": weapon_id,
		}


class PlayerSelectedCharacterModel:
	var player_id: String
	var character_id: int

	static func from_dict(data: Dictionary) -> PlayerSelectedCharacterModel:
		var model := PlayerSelectedCharacterModel.new()
		model.player_id = data.get("player_id", "")
		model.character_id = data.get("character_id", 0)
		return model

	static func from_array(arr: Array) -> Array[PlayerSelectedCharacterModel]:
		var models: Array[PlayerSelectedCharacterModel] = []
		for item in arr:
			models.append(PlayerSelectedCharacterModel.from_dict(item))
		return models

	func to_dict() -> Dictionary:
		return {
			"player_id": player_id,
			"character_id": character_id,
		}


class PlayerAchievementModel:
	var player_id: String
	var achievement_id: int
	var unlock_at: String
	var progress: int

	static func from_dict(data: Dictionary) -> PlayerAchievementModel:
		var model := PlayerAchievementModel.new()
		model.player_id = data.get("player_id", "")
		model.achievement_id = data.get("achievement_id", 0)
		model.unlock_at = str(data.get("unlock_at", ""))
		model.progress = data.get("progress", 0)
		return model

	static func from_array(arr: Array) -> Array[PlayerAchievementModel]:
		var models: Array[PlayerAchievementModel] = []
		for item in arr:
			models.append(PlayerAchievementModel.from_dict(item))
		return models

	func to_dict() -> Dictionary:
		return {
			"player_id": player_id,
			"achievement_id": achievement_id,
			"unlock_at": unlock_at,
			"progress": progress,
		}


class PlayerRankModel:
	var player_id: String
	var season_id: int
	var rank_id: int
	var current_point: int
	var created_at: String
	var updated_at: String

	static func from_dict(data: Dictionary) -> PlayerRankModel:
		var model := PlayerRankModel.new()
		model.player_id = data.get("player_id", "")
		model.season_id = data.get("season_id", 0)
		model.rank_id = data.get("rank_id", 0)
		model.current_point = data.get("current_point", 0)
		model.created_at = data.get("created_at", "")
		model.updated_at = data.get("updated_at", "")
		return model

	static func from_array(arr: Array) -> Array[PlayerRankModel]:
		var models: Array[PlayerRankModel] = []
		for item in arr:
			models.append(PlayerRankModel.from_dict(item))
		return models

	func to_dict() -> Dictionary:
		return {
			"player_id": player_id,
			"season_id": season_id,
			"rank_id": rank_id,
			"current_point": current_point,
			"created_at": created_at,
			"updated_at": updated_at,
		}
