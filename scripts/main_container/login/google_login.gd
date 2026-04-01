extends Node

var google_sign_in: Object = null
@onready var text_edit := $CanvasLayer/Control/TextEdit

func _ready():
	if ApiManager.is_logged_in():
		_go_to_lobby()
		return
	if OS.get_name() == "Android" and Engine.has_singleton("GoogleSignIn"):
		google_sign_in = Engine.get_singleton("GoogleSignIn")
		google_sign_in.connect("sign_in_success", _on_google_sign_in_success)
		google_sign_in.connect("sign_in_failed", _on_sign_in_failed)
		google_sign_in.connect("sign_out_complete", _on_sign_out_complete)

		# Initialize with your Web Client ID
		google_sign_in.initialize("52120121796-8faqr2tmjri3576de2aj30pu0a8ngtf4.apps.googleusercontent.com")
	else:
		text_edit.text = "No plugin installed"

func sign_in():
	if google_sign_in:
		google_sign_in.signInWithGoogleButton()
	else:
		# Sign in with dev account
		PlayerApi.dev_login("SeedBot", "", func(response: Dictionary):
			if response.ok:
				ApiManager.session_token = response.data["session_token"]
				ApiManager.player_id = response.data["player_id"]
				ApiManager.save_session()
				text_edit.text = "Logged in! Player ID: " + str(ApiManager.player_id)
				_go_to_lobby()
			else:
				text_edit.text = "Error: " + response.error
		)

func sign_out():
	if google_sign_in:
		google_sign_in.signOut()
	_send_signout_request()

func _on_google_sign_in_success(id_token: String, _email: String, _display_name: String):
	text_edit.text = "Signing in..."
	_send_login_request(id_token)

func _send_login_request(id_token: String):
	PlayerApi.login(id_token, _on_login_response)

func _on_login_response(result: Dictionary):
	if result.ok:
		ApiManager.session_token = result.data["session_token"]
		ApiManager.player_id = result.data["player_id"]
		ApiManager.save_session()
		text_edit.text = "Logged in! Player ID: " + str(ApiManager.player_id)
		_go_to_lobby()
	else:
		text_edit.text = "Error: " + result.error

func _send_signout_request():
	if not ApiManager.is_logged_in():
		return
	
	PlayerApi.signout(func(response: Dictionary):
		if response.ok:
			ApiManager.clear_session()
			CacheManager.clear_all()
			SceneLoader.load_scene("res://scenes/main_container/login/login.tscn")
		else:
			text_edit.text = "Error: " + response.error
	)

func _on_sign_in_failed(error: String):
	text_edit.text = "Sign-in failed: " + error

func _on_sign_out_complete():
	text_edit.text = "Signed out"

func _go_to_lobby():
	SceneLoader.load_scene("res://scenes/main_container/lobby/lobby.tscn")
