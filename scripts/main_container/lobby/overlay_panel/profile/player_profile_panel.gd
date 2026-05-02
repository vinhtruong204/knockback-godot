class_name PlayerProfilePanel extends Panel

@onready var level_label: Label = $ProfilePanel/Level
@onready var name_label: Label = $ProfilePanel/PlayerName/Label
@onready var avatar: TextureRect = $ProfilePanel/Avatar
@onready var slogan_edit: TextEdit = $ProfilePanel/SloganEditor
@onready var stats_text: RichTextLabel = $StatsPanel/ContentContainer/StatsText

func _ready() -> void:
	self.visibility_changed.connect(_on_visibility_changed)
	slogan_edit.connect("focus_exited", _on_slogan_edit_focus_exited)

	# Default to ranking tab
	on_ranking_button_pressed()

func _on_slogan_edit_focus_exited() -> void:
	PlayerApi.update_player(ApiManager.player_id, {"slogan": slogan_edit.text}, func(response: Dictionary) -> void:
		if response.get("ok", false):
			print("Slogan updated successfully")
		else:
			print("Failed to update slogan")
	)

func _on_visibility_changed() -> void:
	if self.visible:
		PlayerApi.get_player(ApiManager.player_id, func(response: Dictionary) -> void:
			if response.get("ok", false):
				var player = response.get("data")
				level_label.text = "LV. %d" % player.get("current_level_id")
				name_label.text = player.get("name")
				slogan_edit.text = player.get("slogan")
		)

func on_ranking_button_pressed() -> void:
	stats_text.text = "Loading..."
	var pid := ApiManager.player_id

	PlayerApi.get_player_stats_by_mode(pid, Enums.GameMode.RANK, func(stats_response: Dictionary):
		var stats: Dictionary = stats_response.get("data", {}) if stats_response.get("ok", false) else {}

		PlayerApi.get_player_rank(pid, "1", func(rank_response: Dictionary):
			if rank_response.get("ok", false):
				var rank_data: Dictionary = rank_response.get("data", {})

				ConfigApi.get_rank_config(rank_data.get("rank_id", 0), func(config_response: Dictionary):
					var rank_name := "Unknown"
					if config_response.get("ok", false):
						rank_name = config_response.get("data", {}).get("name", "Unknown")

					stats_text.text = "Current rank: %s\n\nRank points: %d\n\nTotal games: %d\n\nWin rate: %s%%\n\nKDA: %s" % [
						rank_name,
						rank_data.get("current_point", 0),
						stats.get("total_game", 0),
						_calc_win_rate(stats.get("number_games_win", 0), stats.get("total_game", 0)),
						_calc_kda(stats.get("kill", 0), stats.get("dead", 0)),
					]
				)
			else:
				stats_text.text = "Total games: %d\n\nWin rate: %s%%\n\nKDA: %s" % [
					stats.get("total_game", 0),
					_calc_win_rate(stats.get("number_games_win", 0), stats.get("total_game", 0)),
					_calc_kda(stats.get("kill", 0), stats.get("dead", 0)),
				]
		)
	)


func on_normal_button_pressed() -> void:
	stats_text.text = "Loading..."
	var pid := ApiManager.player_id

	PlayerApi.get_player_stats_by_mode(pid, Enums.GameMode.NORMAL, func(response: Dictionary):
		var stats: Dictionary = response.get("data", {}) if response.get("ok", false) else {}
		stats_text.text = "Total games: %d\n\nWin rate: %s%%\n\nKDA: %s" % [
			stats.get("total_game", 0),
			_calc_win_rate(stats.get("number_games_win", 0), stats.get("total_game", 0)),
			_calc_kda(stats.get("kill", 0), stats.get("dead", 0)),
		]
	)


func on_achivement_button_pressed() -> void:
	stats_text.text = ""


func _calc_win_rate(wins: int, total: int) -> String:
	if total == 0:
		return "0"
	return "%.1f" % (float(wins) / total * 100.0)


func _calc_kda(kills: int, deaths: int) -> String:
	if deaths == 0:
		return str(kills)
	return "%.2f" % (float(kills) / deaths)
