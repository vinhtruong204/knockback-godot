class_name ConfigModels


class WeaponModel:
	var weapon_id: int
	var name: String
	var weapon_type: String
	var damage: int
	var fire_rate: float
	var image: String
	var ammo: int

	static func from_dict(data: Dictionary) -> WeaponModel:
		var model := WeaponModel.new()
		model.weapon_id = data.get("weapon_id", 0)
		model.name = data.get("name", "")
		model.weapon_type = data.get("weapon_type", "")
		model.damage = data.get("damage", 0)
		model.fire_rate = data.get("fire_rate", 0.0)
		model.image = data.get("image", "")
		model.ammo = data.get("ammo", 0)
		return model

	static func from_array(arr: Array) -> Array[WeaponModel]:
		var models: Array[WeaponModel] = []
		for item in arr:
			models.append(WeaponModel.from_dict(item))
		return models

	func to_dict() -> Dictionary:
		return {
			"weapon_id": weapon_id,
			"name": name,
			"weapon_type": weapon_type,
			"damage": damage,
			"fire_rate": fire_rate,
			"image": image,
			"ammo": ammo,
		}


class CharacterModel:
	var character_id: int
	var name: String
	var character_type: String
	var hp: int
	var run_speed: float
	var texture: String

	static func from_dict(data: Dictionary) -> CharacterModel:
		var model := CharacterModel.new()
		model.character_id = data.get("character_id", 0)
		model.name = data.get("name", "")
		model.character_type = data.get("character_type", "")
		model.hp = data.get("hp", 0)
		model.run_speed = data.get("run_speed", 0.0)
		model.texture = data.get("texture", "")
		return model

	static func from_array(arr: Array) -> Array[CharacterModel]:
		var models: Array[CharacterModel] = []
		for item in arr:
			models.append(CharacterModel.from_dict(item))
		return models

	func to_dict() -> Dictionary:
		return {
			"character_id": character_id,
			"name": name,
			"character_type": character_type,
			"hp": hp,
			"run_speed": run_speed,
			"texture": texture,
		}


class AchievementModel:
	var achievement_id: int
	var name: String
	var image: String
	var requirement: String

	static func from_dict(data: Dictionary) -> AchievementModel:
		var model := AchievementModel.new()
		model.achievement_id = data.get("achievement_id", 0)
		model.name = data.get("name", "")
		model.image = data.get("image", "")
		model.requirement = data.get("requirement", "")
		return model

	static func from_array(arr: Array) -> Array[AchievementModel]:
		var models: Array[AchievementModel] = []
		for item in arr:
			models.append(AchievementModel.from_dict(item))
		return models

	func to_dict() -> Dictionary:
		return {
			"achievement_id": achievement_id,
			"name": name,
			"image": image,
			"requirement": requirement,
		}


class LevelConfigModel:
	var level_id: int
	var min_exp: int
	var max_exp: int
	var reward_gold: int
	var reward_diamond: int

	static func from_dict(data: Dictionary) -> LevelConfigModel:
		var model := LevelConfigModel.new()
		model.level_id = data.get("level_id", 0)
		model.min_exp = data.get("min_exp", 0)
		model.max_exp = data.get("max_exp", 0)
		model.reward_gold = data.get("reward_gold", 0)
		model.reward_diamond = data.get("reward_diamond", 0)
		return model

	static func from_array(arr: Array) -> Array[LevelConfigModel]:
		var models: Array[LevelConfigModel] = []
		for item in arr:
			models.append(LevelConfigModel.from_dict(item))
		return models

	func to_dict() -> Dictionary:
		return {
			"level_id": level_id,
			"min_exp": min_exp,
			"max_exp": max_exp,
			"reward_gold": reward_gold,
			"reward_diamond": reward_diamond,
		}


class RankConfigModel:
	var rank_id: int
	var name: String
	var min_point: int
	var max_point: int
	var image: String

	static func from_dict(data: Dictionary) -> RankConfigModel:
		var model := RankConfigModel.new()
		model.rank_id = data.get("rank_id", 0)
		model.name = data.get("name", "")
		model.min_point = data.get("min_point", 0)
		model.max_point = data.get("max_point", 0)
		model.image = data.get("image", "")
		return model

	static func from_array(arr: Array) -> Array[RankConfigModel]:
		var models: Array[RankConfigModel] = []
		for item in arr:
			models.append(RankConfigModel.from_dict(item))
		return models

	func to_dict() -> Dictionary:
		return {
			"rank_id": rank_id,
			"name": name,
			"min_point": min_point,
			"max_point": max_point,
			"image": image,
		}
