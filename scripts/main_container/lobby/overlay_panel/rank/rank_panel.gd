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

var rank_data: Dictionary = {}
var rank_config: Dictionary = {}
var matchmaking_state: MatchmakingState = MatchmakingState.IDLE
var search_start_time: float = 0.0
var poll_timer: Timer


func _ready():
	# Load rank data from api
	PlayerApi.get_player_rank(ApiManager.player_id, "1", func(response: Dictionary) -> void:
		if response.get("ok", false):
			rank_data = response.get("data", {})

			# Get rank config
			ConfigApi.get_rank_config(rank_data.get("rank_id", ""), func(config_response: Dictionary) -> void:
				if config_response.get("ok", false):
					rank_config = config_response.get("data", {})

					# Set rank data
					rank_name.text = rank_config.get("name", "")
					rank_texture.texture = load("res://assets/lobby/middle/rank/%s" % rank_config.get("image", ""))
					current_point.text = str(int(rank_data.get("current_point", 0))) + " / " + str(int(rank_config.get("max_point", 0)))
				else:
					print("Failed to get rank config")
			)
		else:
			print("Failed to get rank data")
	)

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


func _process(_delta: float) -> void:
	if matchmaking_state == MatchmakingState.SEARCHING:
		var elapsed := Time.get_ticks_msec() / 1000.0 - search_start_time
		var minutes := int(elapsed / 60.0)
		var seconds := int(elapsed) % 60
		timer_label.text = "%02d:%02d" % [minutes, seconds]


# ─── Fight Button ────────────────────────────────────────────
func _on_fight_pressed():
	# test run game directly
	NetworkManager.create_client()
	return

	if matchmaking_state != MatchmakingState.IDLE:
		return

	var rank_point := int(rank_data.get("current_point", 0))
	fight_btn.disabled = true

	MatchApi.join_matchmaking(rank_point, func(response: Dictionary) -> void:
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
				status_label.text = "Searching... (position %d)" % parsed.position
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
	status_label.text = "Searching for match..."
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

	status_label.text = "Match Found!"
	timer_label.text = match_data.map_name
	cancel_btn.visible = false

	# Store match context for the game scene
	NetworkManager.current_match_id = match_data.match_id
	NetworkManager.current_match_players = []
	NetworkManager.current_map_name = match_data.map_name
	for p in match_data.players:
		NetworkManager.current_match_players.append(p.to_dict())

	get_tree().create_timer(1.0).timeout.connect(func():
		NetworkManager.create_client()
	)


# ─── Cleanup ────────────────────────────────────────────────
func _on_visibility_changed():
	if not visible and matchmaking_state == MatchmakingState.SEARCHING:
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
