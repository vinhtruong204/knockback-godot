extends Node

var google_sign_in: Object = null
@onready var text_edit := $CanvasLayer/Control/TextEdit

func _ready():
	# Always set up Google Sign-In first so the re-login path is ready in case
	# session verification below fails.
	if OS.get_name() == "Android" and Engine.has_singleton("GoogleSignIn"):
		google_sign_in = Engine.get_singleton("GoogleSignIn")
		google_sign_in.connect("sign_in_success", _on_google_sign_in_success)
		google_sign_in.connect("sign_in_failed", _on_sign_in_failed)
		google_sign_in.connect("sign_out_complete", _on_sign_out_complete)

		# Initialize with your Web Client ID
		google_sign_in.initialize("52120121796-8faqr2tmjri3576de2aj30pu0a8ngtf4.apps.googleusercontent.com")
	else:
		text_edit.text = tr("LOGIN_NO_PLUGIN")

	# A stored session_token only proves a token *existed* — it might be expired
	# or revoked server-side. Verify it via /auth/refresh before redirecting to
	# the lobby, otherwise the user would land in the lobby and only discover
	# the bad session when subsequent API calls start failing with 401.
	if ApiManager.is_logged_in():
		text_edit.text = tr("LOGIN_VERIFYING")
		PlayerApi.refresh_token(_on_session_verify)


func _on_session_verify(response: Dictionary) -> void:
	if response.get("ok", false):
		# Refresh may rotate the token; persist whichever we got back.
		var data = response.get("data", {})
		if typeof(data) == TYPE_DICTIONARY and data.has("session_token"):
			ApiManager.session_token = data["session_token"]
			ApiManager.save_session()
		_go_to_lobby()
		return

	var status: int = int(response.get("status", 0))
	if status == 401 or status == 403:
		# Token invalid/expired — drop it so the user is forced to sign in.
		ApiManager.clear_session()
		CacheManager.clear_all()
		text_edit.text = tr("LOGIN_SESSION_EXPIRED")
	else:
		# Network or transient server error — keep the stored token (it may
		# work once connectivity returns), but do NOT auto-load the lobby.
		text_edit.text = tr("LOGIN_SESSION_VERIFY_FAIL_PREFIX") + str(response.get("error", "")) + tr("LOGIN_SESSION_VERIFY_FAIL_SUFFIX")

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
				text_edit.text = tr("LOGIN_SUCCESS_PREFIX") + str(ApiManager.player_id)
				_go_to_lobby()
			else:
				text_edit.text = tr("LOGIN_ERR_PREFIX") + str(response.error)
		)

func sign_out():
	if google_sign_in:
		google_sign_in.signOut()
	_send_signout_request()

func _on_google_sign_in_success(id_token: String, _email: String, _display_name: String):
	text_edit.text = tr("LOGIN_SIGNING_IN")
	_send_login_request(id_token)

func _send_login_request(id_token: String):
	PlayerApi.login(id_token, _on_login_response)

func _on_login_response(result: Dictionary):
	if result.ok:
		ApiManager.session_token = result.data["session_token"]
		ApiManager.player_id = result.data["player_id"]
		ApiManager.save_session()
		text_edit.text = tr("LOGIN_SUCCESS_PREFIX") + str(ApiManager.player_id)
		_go_to_lobby()
	else:
		text_edit.text = tr("LOGIN_ERR_PREFIX") + str(result.error)

func _send_signout_request():
	if not ApiManager.is_logged_in():
		return
	
	PlayerApi.signout(func(response: Dictionary):
		if response.ok:
			ApiManager.clear_session()
			CacheManager.clear_all()
			SceneLoader.load_scene("res://scenes/main_container/login/login.tscn")
		else:
			text_edit.text = tr("LOGIN_ERR_PREFIX") + str(response.error)
	)

func _on_sign_in_failed(error: String):
	text_edit.text = tr("LOGIN_SIGNIN_FAIL_PREFIX") + str(error)

func _on_sign_out_complete():
	text_edit.text = tr("LOGIN_SIGNED_OUT")

func _go_to_lobby():
	SceneLoader.load_scene("res://scenes/main_container/lobby/lobby.tscn")
