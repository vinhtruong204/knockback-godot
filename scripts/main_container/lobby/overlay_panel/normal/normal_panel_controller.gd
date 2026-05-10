class_name NormalPanelController extends Panel

@onready var map_btn: Button = $Panel/VBoxContainer/MapBtn
@onready var popup_choose_map: Panel = $PopupChooseMap
@onready var close_btn: Button = $PopupChooseMap/Panel/CloseBtn
@onready var mode_btn: Button = $Panel/VBoxContainer/ModeBtn
@onready var team_size_btn: Button = $Panel/VBoxContainer/TeamSizeBtn
@onready var fight_btn: Button = $Panel/VBoxContainer/FightBtn

enum MatchmakingState { IDLE, SEARCHING, MATCH_FOUND }

var matchmaking_state: MatchmakingState = MatchmakingState.IDLE
var search_start_time: float = 0.0
var poll_timer: Timer
var matchmaking_popup: Panel
var status_label: Label
var timer_label: Label
var cancel_btn: Button

var _maps: Array = []
var _modes: Array = []
var _selected_map_display: String = ""
var _selected_map_key: String = ""


func _ready() -> void:
	map_btn.pressed.connect(_on_map_btn_pressed)
	close_btn.pressed.connect(_on_close_btn_pressed)
	mode_btn.pressed.connect(_on_mode_btn_pressed)
	team_size_btn.pressed.connect(_on_team_size_btn_pressed)
	fight_btn.pressed.connect(_on_fight_btn_pressed)

	team_size_btn.text = "1v1"
	team_size_btn.disabled = true

	poll_timer = Timer.new()
	poll_timer.wait_time = 2.0
	poll_timer.one_shot = false
	poll_timer.timeout.connect(_on_poll_timer_timeout)
	add_child(poll_timer)

	_build_matchmaking_popup()
	visibility_changed.connect(_on_visibility_changed)
	_fetch_match_config()


func _process(_delta: float) -> void:
	if matchmaking_state == MatchmakingState.SEARCHING:
		var elapsed := Time.get_ticks_msec() / 1000.0 - search_start_time
		var minutes := int(elapsed / 60.0)
		var seconds := int(elapsed) % 60
		timer_label.text = "%02d:%02d" % [minutes, seconds]


func _on_map_btn_pressed() -> void:
	popup_choose_map.show()


func _on_close_btn_pressed() -> void:
	popup_choose_map.hide()


func _on_map_selected(map: String) -> void:
	popup_choose_map.hide()
	_selected_map_display = _display_map_name(map)
	_selected_map_key = NetworkManager.get_map_key(_selected_map_display)
	map_btn.text = _selected_map_display


func _on_mode_btn_pressed() -> void:
	if mode_btn.text == "Free for all":
		mode_btn.text = "Search & Destroy"
	else:
		mode_btn.text = "Free for all"


func _on_team_size_btn_pressed() -> void:
	team_size_btn.text = "1v1"


func _on_fight_btn_pressed() -> void:
	if matchmaking_state != MatchmakingState.IDLE:
		return
	if _selected_map_key == "":
		_show_error("Please choose a map first")
		return

	fight_btn.disabled = true
	_ensure_match_config(func():
		_join_normal_matchmaking()
	)


func _join_normal_matchmaking() -> void:
	var map_id := _find_selected_map_id()
	var mode_id := _find_selected_mode_id()
	var payload := {
		"rank_point": 0,
		"game_mode": NetworkManager.GAME_MODE_NORMAL,
		"players_per_team": 1,
	}
	if map_id > 0:
		payload["map_id"] = map_id
	if mode_id > 0:
		payload["mode_id"] = mode_id

	MatchApi.join_matchmaking(payload, func(response: Dictionary) -> void:
		if response.get("ok", false):
			var data: Dictionary = response.get("data", {})
			var parsed = MatchModels.parse_matchmaking_response(data)
			if parsed is MatchModels.MatchmakingQueuedModel:
				_enter_searching_state()
			elif parsed is MatchModels.MatchmakingMatchFoundModel:
				_handle_match_found(parsed)
			else:
				_show_error("Unexpected matchmaking status")
				_enter_idle_state()
		else:
			if response.get("status", 0) == 409:
				_enter_searching_state()
			else:
				_show_error("Failed to join matchmaking")
				_enter_idle_state()
	)


func _on_cancel_pressed() -> void:
	if matchmaking_state == MatchmakingState.MATCH_FOUND:
		return
	MatchApi.leave_matchmaking(func(_response: Dictionary) -> void:
		_enter_idle_state()
	)


func _on_poll_timer_timeout() -> void:
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


func _enter_searching_state() -> void:
	matchmaking_state = MatchmakingState.SEARCHING
	search_start_time = Time.get_ticks_msec() / 1000.0
	fight_btn.disabled = true
	matchmaking_popup.visible = true
	status_label.text = "Searching for match..."
	timer_label.text = "00:00"
	cancel_btn.visible = true
	cancel_btn.disabled = false
	poll_timer.start()


func _enter_idle_state() -> void:
	matchmaking_state = MatchmakingState.IDLE
	fight_btn.disabled = false
	matchmaking_popup.visible = false
	poll_timer.stop()


func _handle_match_found(match_data) -> void:
	matchmaking_state = MatchmakingState.MATCH_FOUND
	poll_timer.stop()
	status_label.text = "Match Found!"
	var matched_map_name := str(match_data.map_name).strip_edges()
	if matched_map_name == "":
		matched_map_name = _selected_map_display
	var matched_map_key := NetworkManager.get_map_key(matched_map_name)
	timer_label.text = _display_map_name(matched_map_name)
	cancel_btn.visible = false

	var players: Array = []
	for p in match_data.players:
		players.append(p.to_dict())

	get_tree().create_timer(1.0).timeout.connect(func():
		NetworkManager.start_online_match({
			"game_mode": NetworkManager.GAME_MODE_NORMAL,
			"match_id": match_data.match_id,
			"players": players,
			"map_name": matched_map_name,
			"map_key": matched_map_key,
		})
	)


func _fetch_match_config(done: Callable = Callable()) -> void:
	var pending := {"count": 2}
	var maybe_done := func():
		pending["count"] -= 1
		if pending["count"] <= 0 and done.is_valid():
			done.call()

	MatchApi.get_maps(func(response: Dictionary) -> void:
		if response.get("ok", false):
			_maps = response.get("data", [])
		maybe_done.call()
	, true)

	MatchApi.get_modes(func(response: Dictionary) -> void:
		if response.get("ok", false):
			_modes = response.get("data", [])
		maybe_done.call()
	, true)


func _ensure_match_config(done: Callable) -> void:
	if not _maps.is_empty() and not _modes.is_empty():
		done.call()
	else:
		_fetch_match_config(done)


func _find_selected_map_id() -> int:
	var fallback := 0
	for item in _maps:
		if not (item is Dictionary):
			continue
		if fallback == 0:
			fallback = int(item.get("map_id", 0))
		var map_name := str(item.get("name", ""))
		var image := str(item.get("image", ""))
		if NetworkManager.get_map_key(map_name) == _selected_map_key or NetworkManager.get_map_key(image.get_basename()) == _selected_map_key:
			return int(item.get("map_id", 0))
	return fallback


func _find_selected_mode_id() -> int:
	var fallback := 0
	var wanted := mode_btn.text.strip_edges().to_lower()
	for item in _modes:
		if not (item is Dictionary):
			continue
		var mode_type := str(item.get("type", "")).to_lower()
		if mode_type != NetworkManager.GAME_MODE_NORMAL:
			continue
		if fallback == 0:
			fallback = int(item.get("mode_id", 0))
		var mode_name := str(item.get("name", "")).strip_edges().to_lower()
		if mode_name == wanted:
			return int(item.get("mode_id", 0))
	return fallback


func _display_map_name(map: String) -> String:
	var key := NetworkManager.get_map_key(map)
	match key:
		"night":
			return "Night"
		"ice":
			return "Ice"
		"dust":
			return "Dust"
		"forest":
			return "Forest"
		_:
			return map


func _build_matchmaking_popup() -> void:
	matchmaking_popup = Panel.new()
	matchmaking_popup.name = "MatchmakingPopup"
	matchmaking_popup.visible = false
	matchmaking_popup.z_index = 20
	matchmaking_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(matchmaking_popup)

	var container := VBoxContainer.new()
	container.custom_minimum_size = Vector2(360, 180)
	container.set_anchors_preset(Control.PRESET_CENTER)
	container.offset_left = -180
	container.offset_top = -90
	container.offset_right = 180
	container.offset_bottom = 90
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 16)
	matchmaking_popup.add_child(container)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.text = "Searching for match..."
	status_label.add_theme_font_size_override("font_size", 26)
	container.add_child(status_label)

	timer_label = Label.new()
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.text = "00:00"
	timer_label.add_theme_font_size_override("font_size", 24)
	container.add_child(timer_label)

	cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(160, 50)
	cancel_btn.pressed.connect(_on_cancel_pressed)
	container.add_child(cancel_btn)


func _on_visibility_changed() -> void:
	if not visible and matchmaking_state == MatchmakingState.SEARCHING:
		MatchApi.leave_matchmaking(func(_response: Dictionary) -> void:
			pass
		)
		_enter_idle_state()


func _exit_tree() -> void:
	if matchmaking_state == MatchmakingState.SEARCHING:
		MatchApi.leave_matchmaking(func(_response: Dictionary) -> void:
			pass
		)
	if poll_timer:
		poll_timer.stop()


func _show_error(message: String) -> void:
	var global_ui = get_tree().root.get_node_or_null("Main/GlobalUi")
	if global_ui:
		global_ui.show_error_notification(message)
	else:
		print(message)
