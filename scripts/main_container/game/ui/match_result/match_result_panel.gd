class_name MatchResultPanel extends Control

@onready var result_label: Label = $BgOverlay/Panel/MarginContainer/VBoxContainer/ResultLabel
@onready var p1_name: Label = $BgOverlay/Panel/MarginContainer/VBoxContainer/Player1Row/P1Name
@onready var p1_kill: Label = $BgOverlay/Panel/MarginContainer/VBoxContainer/Player1Row/P1Kill
@onready var p1_dead: Label = $BgOverlay/Panel/MarginContainer/VBoxContainer/Player1Row/P1Dead
@onready var p1_gold: Label = $BgOverlay/Panel/MarginContainer/VBoxContainer/Player1Row/P1Gold
@onready var p1_exp: Label = $BgOverlay/Panel/MarginContainer/VBoxContainer/Player1Row/P1Exp
@onready var p1_rank: Label = $BgOverlay/Panel/MarginContainer/VBoxContainer/Player1Row/P1Rank
@onready var p2_name: Label = $BgOverlay/Panel/MarginContainer/VBoxContainer/Player2Row/P2Name
@onready var p2_kill: Label = $BgOverlay/Panel/MarginContainer/VBoxContainer/Player2Row/P2Kill
@onready var p2_dead: Label = $BgOverlay/Panel/MarginContainer/VBoxContainer/Player2Row/P2Dead
@onready var p2_gold: Label = $BgOverlay/Panel/MarginContainer/VBoxContainer/Player2Row/P2Gold
@onready var p2_exp: Label = $BgOverlay/Panel/MarginContainer/VBoxContainer/Player2Row/P2Exp
@onready var p2_rank: Label = $BgOverlay/Panel/MarginContainer/VBoxContainer/Player2Row/P2Rank
@onready var confirm_btn: Button = $BgOverlay/Panel/MarginContainer/VBoxContainer/ConfirmBtn

var my_reward_gold: int = 0
var my_exp_earned: int = 0
var my_rank_point_change: int = 0
var my_result: String = ""
var my_kills: int = 0
var my_deaths: int = 0
var result_game_mode: String = "rank"

const COUNTDOWN_SECONDS := 5
var _countdown: int = COUNTDOWN_SECONDS
var _countdown_timer: Timer


func _ready() -> void:
	confirm_btn.pressed.connect(_on_confirm_pressed)
	visible = false

	# Auto-confirm countdown timer
	_countdown_timer = Timer.new()
	_countdown_timer.wait_time = 1.0
	_countdown_timer.one_shot = false
	_countdown_timer.timeout.connect(_on_countdown_tick)
	add_child(_countdown_timer)


func show_result(my_data: Dictionary, opponent_data: Dictionary) -> void:
	visible = true
	result_game_mode = NetworkManager.current_game_mode

	my_result = my_data.get("result", "")
	my_reward_gold = my_data.get("reward_gold", 0)
	my_exp_earned = my_data.get("exp_earned", 0)
	my_rank_point_change = my_data.get("rank_point_change", 0)
	my_kills = my_data.get("kill", 0)
	my_deaths = my_data.get("dead", 0)

	# Header
	if my_result == Enums.MatchResult.WIN:
		result_label.text = "VICTORY"
		result_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		result_label.text = "DEFEAT"
		result_label.add_theme_color_override("font_color", Color.RED)

	# Your row
	p1_name.text = my_data.get("name", "You")
	p1_kill.text = str(my_data.get("kill", 0))
	p1_dead.text = str(my_data.get("dead", 0))
	p1_gold.text = "+%d" % my_reward_gold
	p1_exp.text = "+%d" % my_exp_earned
	p1_rank.text = "%+d" % my_rank_point_change

	# Highlight your row
	if my_result == Enums.MatchResult.WIN:
		_set_row_color($BgOverlay/Panel/MarginContainer/VBoxContainer/Player1Row, Color(0.2, 0.8, 0.2))
	else:
		_set_row_color($BgOverlay/Panel/MarginContainer/VBoxContainer/Player1Row, Color(0.8, 0.2, 0.2))

	# Opponent row
	p2_name.text = opponent_data.get("name", "Opponent")
	p2_kill.text = str(opponent_data.get("kill", 0))
	p2_dead.text = str(opponent_data.get("dead", 0))
	p2_gold.text = "+%d" % opponent_data.get("reward_gold", 0)
	p2_exp.text = "+%d" % opponent_data.get("exp_earned", 0)
	p2_rank.text = "%+d" % opponent_data.get("rank_point_change", 0)

	# Start countdown
	_countdown = COUNTDOWN_SECONDS
	confirm_btn.text = "Confirm (%d)" % _countdown
	_countdown_timer.start()


func _set_row_color(row: HBoxContainer, color: Color) -> void:
	for child in row.get_children():
		if child is Label:
			child.add_theme_color_override("font_color", color)


func _on_countdown_tick() -> void:
	_countdown -= 1
	if _countdown <= 0:
		_countdown_timer.stop()
		_on_confirm_pressed()
	else:
		confirm_btn.text = "Confirm (%d)" % _countdown


func _on_confirm_pressed() -> void:
	_countdown_timer.stop()
	confirm_btn.disabled = true
	confirm_btn.text = "Leaving..."
	var pid := ApiManager.player_id

	if result_game_mode == NetworkManager.GAME_MODE_LAN:
		_finalize_and_leave()
		return

	# 1. Add gold reward
	if my_reward_gold > 0:
		PlayerApi.add_player_currency_amount(pid, Enums.CurrencyType.GOLD,
			{"amount": my_reward_gold}, func(_r): pass)

	# 2. Update match-player record with full stats
	var mid := str(NetworkManager.current_match_id)
	if mid != "0":
		MatchApi.update_match_player(mid, pid, {
			"kill": my_kills,
			"dead": my_deaths,
			"result": my_result,
			"exp_earned": my_exp_earned,
			"reward_gold": my_reward_gold,
		}, func(_r): pass)

	# 3. Add EXP to player profile
	if my_exp_earned > 0:
		PlayerApi.get_player(pid, func(profile_response: Dictionary):
			if profile_response.get("ok", false):
				var current_exp: int = profile_response.get("data", {}).get("current_exp", 0)
				PlayerApi.update_player(pid, {"current_exp": current_exp + my_exp_earned}, func(_r): pass)
		, true)

	# 4. Update cumulative player stats (kill, dead, total_game, wins)
	var stats_mode := Enums.GameMode.RANK if result_game_mode == NetworkManager.GAME_MODE_RANK else Enums.GameMode.NORMAL
	PlayerApi.get_player_stats_by_mode(pid, stats_mode, func(stats_response: Dictionary):
		if stats_response.get("ok", false):
			var stats: Dictionary = stats_response.get("data", {})
			var update_data := {
				"kill": stats.get("kill", 0) + my_kills,
				"dead": stats.get("dead", 0) + my_deaths,
				"total_game": stats.get("total_game", 0) + 1,
				"number_games_win": stats.get("number_games_win", 0) + (1 if my_result == Enums.MatchResult.WIN else 0),
			}
			PlayerApi.update_player_stats(pid, stats_mode, update_data, func(_r): pass)
	, true)

	# 5. Fetch current rank, compute new value, then update
	if result_game_mode != NetworkManager.GAME_MODE_RANK:
		_finalize_and_leave()
		return

	_update_player_rank_after_match(pid)


func _update_player_rank_after_match(pid: String) -> void:
	PlayerApi.get_player_rank(pid, "1", func(response: Dictionary):
		if response.get("ok", false):
			var current_point: int = response.get("data", {}).get("current_point", 0)
			var new_point: int = max(0, current_point + my_rank_point_change)

			CacheManager.invalidate("config:rank_configs")
			ConfigApi.get_rank_configs(func(config_response: Dictionary) -> void:
				var update_data := {"current_point": new_point}
				if config_response.get("ok", false):
					var resolved_rank_id := _resolve_rank_id_for_points(
						new_point,
						_extract_rank_configs(config_response.get("data", [])),
						int(response.get("data", {}).get("rank_id", 0))
					)
					if resolved_rank_id > 0:
						update_data["rank_id"] = resolved_rank_id
				else:
					print("Failed to get rank configs while updating rank: ", config_response.get("error", ""))

				PlayerApi.update_player_rank(pid, "1", update_data, func(_r2):
					_finalize_and_leave()
				)
			)
		else:
			_finalize_and_leave()
	)


func _extract_rank_configs(data: Variant) -> Array:
	if data is Array:
		return data

	if data is Dictionary:
		for key in ["items", "results", "rank_configs", "data"]:
			var nested = data.get(key)
			if nested is Array:
				return nested

	return []


func _resolve_rank_id_for_points(points: int, rank_configs: Array, fallback_rank_id: int) -> int:
	var configs: Array = []
	for config in rank_configs:
		if config is Dictionary:
			configs.append(config)
	if configs.is_empty():
		return fallback_rank_id

	configs.sort_custom(func(a, b): return int(a.get("min_point", 0)) < int(b.get("min_point", 0)))

	var resolved_rank_id := int(configs[0].get("rank_id", fallback_rank_id))
	for config in configs:
		if points >= int(config.get("min_point", 0)):
			resolved_rank_id = int(config.get("rank_id", resolved_rank_id))
		else:
			break
	return resolved_rank_id


func _finalize_and_leave() -> void:
	# Winner updates match status to finished with end_time
	if result_game_mode != NetworkManager.GAME_MODE_LAN and my_result == Enums.MatchResult.WIN:
		var mid := str(NetworkManager.current_match_id)
		if mid != "0":
			MatchApi.update_match(mid, {
				"status": Enums.MatchStatus.FINISHED,
				"end_time": Time.get_datetime_string_from_system(true),
			}, func(_r): pass)

	# Invalidate caches so lobby shows updated data
	CacheManager.invalidate_category("player_dynamic")
	CacheManager.invalidate("player:ranks:" + ApiManager.player_id)
	CacheManager.invalidate("player:stats:" + ApiManager.player_id)

	NetworkManager.leave_game()
