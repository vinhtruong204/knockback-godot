class_name LobbyUIManager extends Control

@onready var _team_1_btn: Button = $UIButtons/Middle/HBoxContainer/Team1Btn
@onready var _team_2_btn: Button = $UIButtons/Middle/HBoxContainer/Team2Btn
@onready var _equipment_panel: Panel = $OverlayContainer/Equipment

func _init() -> void:
	# Get player information
	PlayerApi.get_player(ApiManager.player_id, func(response: Dictionary):
		if response.get("ok", false):
			var player = response.get("data")
			NetworkManager.current_player_name = player.get("name", "")
			print(player)
	)


func _ready() -> void:
	_refresh_character_team_buttons()
	_equipment_panel.visibility_changed.connect(_on_equipment_visibility_changed)


func _on_equipment_visibility_changed() -> void:
	if not _equipment_panel.visible:
		_refresh_character_team_buttons()


func _refresh_character_team_buttons() -> void:
	PlayerApi.get_selected_character(ApiManager.player_id, func(response: Dictionary):
		if not response.get("ok", false):
			return
		var character_id = int(response.get("data", {}).get("character_id", 0))
		if character_id <= 0:
			return
		ConfigApi.get_character(character_id, func(char_response: Dictionary):
			if not char_response.get("ok", false):
				return
			var texture_name = char_response.get("data", {}).get("texture", "")
			if texture_name == "":
				return
			var tex = load("res://assets/game/player/%s" % texture_name)
			_team_1_btn.icon = tex
			_team_2_btn.icon = tex
		)
	, true)

func _ignore_ui_buttons_input():
	%UIButtons.mouse_filter = Control.MOUSE_FILTER_IGNORE

#region Overlay
func _open_player_profile():
	$OverlayContainer/PlayerProfile.visible = true
	_ignore_ui_buttons_input()

func _open_equipment():
	$OverlayContainer/Equipment.visible = true
	_ignore_ui_buttons_input()

func _open_leaderboard():
	$OverlayContainer/Leaderboard.visible = true
	_ignore_ui_buttons_input()

func _open_ranking():
	$OverlayContainer/Ranking.visible = true
	_ignore_ui_buttons_input()

func _open_normal():
	$OverlayContainer/Normal.visible = true
	_ignore_ui_buttons_input()
	
func _open_lan():
	$OverlayContainer/LAN.visible = true
	_ignore_ui_buttons_input()

func _open_shop():
	$OverlayContainer/Shop.visible = true
	_ignore_ui_buttons_input()

func _open_wheel():
	$OverlayContainer/Wheel.visible = true
	_ignore_ui_buttons_input()

func _open_task():
	$OverlayContainer/Task.visible = true
	_ignore_ui_buttons_input()
#endregion

#region Top overlay
func _open_purchase():
	$TopOverlay/Purchase.visible = true
	_ignore_ui_buttons_input()

func _open_settings():
	$TopOverlay/Settings.visible = true
	_ignore_ui_buttons_input()

func _sign_out() -> void:
	if OS.get_name() == "Android" and Engine.has_singleton("GoogleSignIn"):
		var google_sign_in = Engine.get_singleton("GoogleSignIn")
		await google_sign_in.signOut()

	PlayerApi.signout(func(response: Dictionary):
		if response.ok:
			ApiManager.clear_session()
			CacheManager.clear_all()
			SceneLoader.load_scene("res://scenes/main_container/login/login.tscn")
		else:
			print("Sign out error: " + response.error)
	)
#endregion
