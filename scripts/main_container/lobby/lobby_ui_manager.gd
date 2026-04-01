class_name LobbyUIManager extends Control

func _init() -> void:
	# Get player information
	PlayerApi.get_player(ApiManager.player_id, func(response: Dictionary):
		if response.get("ok", false):
			var player = response.get("data")
			print(player)
	)

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
