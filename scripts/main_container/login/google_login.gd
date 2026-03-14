extends Node

var google_sign_in: Object = null
@onready var text_edit := $CanvasLayer/Control/TextEdit

func _ready():
	if OS.get_name() == "Android" and Engine.has_singleton("GoogleSignIn"):
		google_sign_in = Engine.get_singleton("GoogleSignIn")
		google_sign_in.connect("sign_in_success", _on_sign_in_success)
		google_sign_in.connect("sign_in_failed", _on_sign_in_failed)
		google_sign_in.connect("sign_out_complete", _on_sign_out_complete)
		
		# Initialize with your Web Client ID
		google_sign_in.initialize("52120121796-1jbtdf1jel0mn69fsflfkinn6ot96q1u.apps.googleusercontent.com")
	else:
		text_edit.text = "No plugin installed"

func sign_in():
	if google_sign_in:
		# google_sign_in.signIn() # Auto-selects if previously signed in
		google_sign_in.signInWithGoogleButton() # Always shows account picker

func sign_out():
	if google_sign_in:
		google_sign_in.signOut()

func _on_sign_in_success(id_token: String, email: String, display_name: String):
	print("Signed in as: ", email)
	print("Display name: ", display_name)
	# Use id_token with Firebase Auth:
	# https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp
	
	text_edit.text = """
Signed in as: %s
Display name: %s
Id token: %s
""" % [email, display_name, id_token]

func _on_sign_in_failed(error: String):
	print("Sign-in failed: ", error)
	text_edit.text = error

func _on_sign_out_complete():
	print("Signed out")
