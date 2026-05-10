class_name RankPanel extends Panel

@onready var rank_name: Label = $Panel/RankName
@onready var rank_texture: TextureRect = $Panel/RankTexture
@onready var current_point: Label = $Panel/CurrentPoint
@onready var fight_btn: Button = $Panel/FightBtn

@onready var matchmaking_popup: Panel = $MatchmakingPopup
@onready var status_label: Label = $MatchmakingPopup/Panel/StatusLabel
@onready var timer_label: Label = $MatchmakingPopup/Panel/TimerLabel
@onready var cancel_btn: Button = $MatchmakingPopup/Panel/CancelBtn

enum MatchmakingState {IDLE, SEARCHING, MATCH_FOUND}

const DEFAULT_RANK_CONFIGS: Array[Dictionary] = [
	{"rank_id": 1, "min_point": 0, "max_point": 499, "image": "bronze.png", "name": "Bronze"},
	{"rank_id": 2, "min_point": 500, "max_point": 999, "image": "silver.png", "name": "Silver"},
	{"rank_id": 3, "min_point": 1000, "max_point": 1499, "image": "gold.png", "name": "Gold"},
	{"rank_id": 4, "min_point": 1500, "max_point": 1999, "image": "platinum.png", "name": "Platinum"},
	{"rank_id": 5, "min_point": 2000, "max_point": 2499, "image": "diamond.png", "name": "Diamond"},
	{"rank_id": 6, "min_point": 2500, "max_point": 9999, "image": "master.png", "name": "Master"},
]

const RANK_NAME_KEYS := {
	"Bronze": "RANK_BRONZE",
	"Silver": "RANK_SILVER",
	"Gold": "RANK_GOLD",
	"Platinum": "RANK_PLATINUM",
	"Diamond": "RANK_DIAMOND",
	"Master": "RANK_MASTER",
}


func _translate_rank_name(name: String) -> String:
	var key: String = RANK_NAME_KEYS.get(name, "")
	if key == "":
		return name
	return tr(key)

var rank_data: Dictionary = {}
var rank_config: Dictionary = {}
var matchmaking_state: MatchmakingState = MatchmakingState.IDLE
var search_start_time: float = 0.0
var poll_timer: Timer


func _ready():
	fight_btn.pressed.connect(_on_fight_pressed)
	cancel_btn.pressed.connect(_on_cancel_pressed)

	# Polling timer for matchmaking status
	poll_timer = Timer.new()
	poll_timer.wait_time = 2.0
	poll_timer.one_shot = false
	poll_timer.timeout.connect(_on_poll_timer_timeout)
	add_child(poll_timer)

	matchmaking_popup.visible = false
	visibility_changed.connect(_on_visibility_changed)
	_populate_tier_info_buttons()
	_refresh_rank_display()


func _populate_tier_info_buttons() -> void:
	var grid := $PopupAllRankInfor/Panel/ScrollContainer/VBoxContainer/GridContainer
	var buttons := grid.get_children()
	for i in range(min(buttons.size(), DEFAULT_RANK_CONFIGS.size())):
		var cfg := DEFAULT_RANK_CONFIGS[i]
		var btn := buttons[i] as Button
		if btn == null:
			continue
		btn.text = tr("RANK_TIER_FMT") % [
			_translate_rank_name(str(cfg.get("name", ""))),
			int(cfg.get("min_point", 0)),
			int(cfg.get("max_point", 0)),
		]


func _refresh_rank_display() -> void:
	PlayerApi.get_player_rank(ApiManager.player_id, "1", func(response: Dictionary) -> void:
		if response.get("ok", false):
			rank_data = response.get("data", {})

			CacheManager.invalidate("config:rank_configs")
			ConfigApi.get_rank_configs(func(config_response: Dictionary) -> void:
				if config_response.get("ok", false):
					var rank_configs := _extract_rank_configs(config_response.get("data", []))
					var resolved_config := _resolve_rank_config_for_points(
						int(rank_data.get("current_point", 0)),
						rank_configs
					)
					if resolved_config.is_empty():
						_apply_default_or_rank_id_config()
						return

					_apply_rank_config(resolved_config)
				else:
					print("Failed to get rank configs")
					_apply_default_or_rank_id_config()
			)
		else:
			print("Failed to get rank data")
	)


func _refresh_rank_display_from_rank_id() -> void:
	CacheManager.invalidate("config:rank_configs:%d" % int(rank_data.get("rank_id", 0)))
	ConfigApi.get_rank_config(int(rank_data.get("rank_id", 0)), func(config_response: Dictionary) -> void:
		if config_response.get("ok", false):
			_apply_rank_config(config_response.get("data", {}))
		else:
			print("Failed to get rank config")
	)


func _apply_default_or_rank_id_config() -> void:
	var resolved_config := _resolve_rank_config_for_points(
		int(rank_data.get("current_point", 0)),
		DEFAULT_RANK_CONFIGS
	)
	if not resolved_config.is_empty():
		_apply_rank_config(resolved_config)
		return

	_refresh_rank_display_from_rank_id()


func _extract_rank_configs(data: Variant) -> Array:
	if data is Array:
		return data

	if data is Dictionary:
		for key in ["items", "results", "rank_configs", "data"]:
			var nested = data.get(key)
			if nested is Array:
				return nested

	return []


func _resolve_rank_config_for_points(points: int, rank_configs: Array) -> Dictionary:
	var configs: Array = []
	for config in rank_configs:
		if config is Dictionary:
			configs.append(config)
	if configs.is_empty():
		return {}

	configs.sort_custom(func(a, b): return int(a.get("min_point", 0)) < int(b.get("min_point", 0)))

	var resolved_config: Dictionary = configs[0]
	for config in configs:
		if points >= int(config.get("min_point", 0)):
			resolved_config = config
		else:
			break
	return resolved_config


func _apply_rank_config(config: Dictionary) -> void:
	rank_config = config
	rank_name.text = _translate_rank_name(str(rank_config.get("name", "")))
	_set_rank_texture(str(rank_config.get("image", "")))
	current_point.text = "%d / %d" % [
		int(rank_data.get("current_point", 0)),
		int(rank_config.get("max_point", 0))
	]


func _set_rank_texture(image_name: String) -> void:
	if image_name == "":
		rank_texture.texture = null
		return

	var texture_path := "res://assets/lobby/middle/rank/%s" % image_name
	var texture = load(texture_path)
	if texture:
		rank_texture.texture = texture
	else:
		print("Missing rank texture: ", texture_path)


func _process(_delta: float) -> void:
	if matchmaking_state == MatchmakingState.SEARCHING:
		var elapsed := Time.get_ticks_msec() / 1000.0 - search_start_time
		var minutes := int(elapsed / 60.0)
		var seconds := int(elapsed) % 60
		timer_label.text = "%02d:%02d" % [minutes, seconds]


# ─── Fight Button ────────────────────────────────────────────
func _on_fight_pressed():
	if matchmaking_state != MatchmakingState.IDLE:
		return

	var rank_point := int(rank_data.get("current_point", 0))
	fight_btn.disabled = true

	MatchApi.join_matchmaking({
		"rank_point": rank_point,
		"game_mode": NetworkManager.GAME_MODE_RANK,
		"players_per_team": 1,
	}, func(response: Dictionary) -> void:
		if response.get("ok", false):
			var data: Dictionary = response.get("data", {})
			var parsed = MatchModels.parse_matchmaking_response(data)

			if parsed is MatchModels.MatchmakingQueuedModel:
				_enter_searching_state()
			elif parsed is MatchModels.MatchmakingMatchFoundModel:
				_handle_match_found(parsed)
			else:
				print("Unexpected join response: ", data.get("status", ""))
				fight_btn.disabled = false
		else:
			if response.get("status", 0) == 409:
				_enter_searching_state()
			else:
				print("Failed to join matchmaking: ", response.get("error", ""))
				fight_btn.disabled = false
	)


# ─── Cancel Button ───────────────────────────────────────────
func _on_cancel_pressed():
	if matchmaking_state == MatchmakingState.MATCH_FOUND:
		return

	MatchApi.leave_matchmaking(func(_response: Dictionary) -> void:
		_enter_idle_state()
	)


# ─── Polling ─────────────────────────────────────────────────
func _on_poll_timer_timeout():
	if matchmaking_state != MatchmakingState.SEARCHING:
		return

	MatchApi.get_matchmaking_status(func(response: Dictionary) -> void:
		if matchmaking_state != MatchmakingState.SEARCHING:
			return

		if response.get("ok", false):
			var data: Dictionary = response.get("data", {})
			var parsed = MatchModels.parse_matchmaking_response(data)

			if parsed is MatchModels.MatchmakingMatchFoundModel:
				_handle_match_found(parsed)
			elif parsed is MatchModels.MatchmakingMatchedModel:
				_handle_match_found(parsed)
			elif parsed is MatchModels.MatchmakingWaitingModel:
				status_label.text = tr("MM_SEARCHING_POS_FMT") % parsed.position
			elif parsed is MatchModels.MatchmakingNoneModel:
				_enter_idle_state()
		else:
			print("Poll error: ", response.get("error", ""))
	)


# ─── State Transitions ──────────────────────────────────────
func _enter_searching_state():
	matchmaking_state = MatchmakingState.SEARCHING
	search_start_time = Time.get_ticks_msec() / 1000.0
	fight_btn.disabled = true
	matchmaking_popup.visible = true
	status_label.text = tr("MM_SEARCHING")
	timer_label.text = "00:00"
	cancel_btn.visible = true
	cancel_btn.disabled = false
	poll_timer.start()


func _enter_idle_state():
	matchmaking_state = MatchmakingState.IDLE
	fight_btn.disabled = false
	matchmaking_popup.visible = false
	poll_timer.stop()


func _handle_match_found(match_data) -> void:
	matchmaking_state = MatchmakingState.MATCH_FOUND
	poll_timer.stop()

	status_label.text = tr("MM_FOUND")
	timer_label.text = match_data.map_name
	cancel_btn.visible = false

	# Store match context for the game scene
	var players: Array = []
	for p in match_data.players:
		players.append(p.to_dict())

	get_tree().create_timer(1.0).timeout.connect(func():
		NetworkManager.start_online_match({
			"game_mode": NetworkManager.GAME_MODE_RANK,
			"match_id": match_data.match_id,
			"players": players,
			"map_name": match_data.map_name,
			"map_key": NetworkManager.get_map_key(match_data.map_name),
		})
	)


# ─── Cleanup ────────────────────────────────────────────────
func _on_visibility_changed():
	if visible:
		_refresh_rank_display()
		return

	if matchmaking_state == MatchmakingState.SEARCHING:
		MatchApi.leave_matchmaking(func(_response: Dictionary) -> void:
			pass
		)
		_enter_idle_state()


func _exit_tree():
	if matchmaking_state == MatchmakingState.SEARCHING:
		MatchApi.leave_matchmaking(func(_response: Dictionary) -> void:
			pass
		)
	poll_timer.stop()


# ─── Existing ───────────────────────────────────────────────
func _on_help_pressed():
	$PopupAllRankInfor.show()


func _on_close_pressed():
	$PopupAllRankInfor.hide()
