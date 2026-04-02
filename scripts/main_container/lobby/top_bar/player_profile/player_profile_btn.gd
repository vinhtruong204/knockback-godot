class_name PlayerProfileBtn extends TextureButton

@onready var player_name: Label = $PlayerName
@onready var level: Label = $Level
@onready var avatar: TextureRect = $Avatar

func _init() -> void:
	PlayerApi.get_player(ApiManager.player_id, func(response: Dictionary) -> void:
		if response.get("ok", false):
			var player = response.get("data")
			player_name.text = player.get("name")
			level.text = "LV. %d" % int(player.get("current_level_id"))
	)
