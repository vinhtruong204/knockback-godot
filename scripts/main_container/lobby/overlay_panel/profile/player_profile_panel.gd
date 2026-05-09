class_name PlayerProfilePanel extends Panel

@export var achievement_card_scene: PackedScene

@onready var level_label: Label = $ProfilePanel/Level
@onready var name_label: Label = $ProfilePanel/PlayerName/Label
@onready var avatar: TextureRect = $ProfilePanel/Avatar
@onready var slogan_edit: TextEdit = $ProfilePanel/SloganEditor
@onready var stats_text: RichTextLabel = $StatsPanel/ContentContainer/StatsText
@onready var scroll_container: ScrollContainer = $StatsPanel/ContentContainer/ScrollContainer
@onready var achievement_list: VBoxContainer = $StatsPanel/ContentContainer/ScrollContainer/VBoxContainer

func _ready() -> void:
	self.visibility_changed.connect(_on_visibility_changed)
	slogan_edit.connect("focus_exited", _on_slogan_edit_focus_exited)

	# Default to ranking tab
	_show_tab("stats")
	on_ranking_button_pressed()


func _show_tab(tab: String) -> void:
	# tab: "stats" (Ranking + Normal share StatsText) or "achievement"
	var is_stats := tab == "stats"
	stats_text.visible = is_stats
	scroll_container.visible = not is_stats

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
	_show_tab("stats")
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
	_show_tab("stats")
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
	_show_tab("achievement")
	_load_achievements()


func _load_achievements() -> void:
	for child in achievement_list.get_children():
		child.queue_free()

	var pid := ApiManager.player_id
	ConfigApi.get_achievements(func(catalog_response: Dictionary):
		if not catalog_response.get("ok", false):
			print("[PlayerProfile] Failed to load achievements catalog: ", catalog_response.get("error", ""))
			return
		var catalog: Array = catalog_response.get("data", [])

		PlayerApi.get_player_achievements(pid, func(progress_response: Dictionary):
			var progress_by_id: Dictionary = {}
			if progress_response.get("ok", false):
				for entry in progress_response.get("data", []):
					progress_by_id[int(entry.get("achievement_id", -1))] = entry
			else:
				print("[PlayerProfile] Failed to load player achievements: ", progress_response.get("error", ""))

			for achievement in catalog:
				var card = achievement_card_scene.instantiate()
				achievement_list.add_child(card)
				var aid := int(achievement.get("achievement_id", -1))
				var progress = progress_by_id.get(aid, null)
				card.set_data(achievement, progress)
		)
	)


func _calc_win_rate(wins: int, total: int) -> String:
	if total == 0:
		return "0"
	return "%.1f" % (float(wins) / total * 100.0)


func _calc_kda(kills: int, deaths: int) -> String:
	if deaths == 0:
		return str(kills)
	return "%.2f" % (float(kills) / deaths)
