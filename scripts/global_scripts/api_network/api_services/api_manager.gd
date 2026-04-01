extends Node

const AUTH_SAVE_PATH := "user://auth.cfg"

var host := "http://100.96.156.107"
var session_token := ""
var player_id := ""

func _ready():
	load_session()

func is_logged_in() -> bool:
	return session_token != ""

func save_session():
	var config := ConfigFile.new()
	config.set_value("auth", "session_token", session_token)
	config.set_value("auth", "player_id", player_id)
	config.save(AUTH_SAVE_PATH)

func load_session():
	var config := ConfigFile.new()
	if config.load(AUTH_SAVE_PATH) == OK:
		session_token = config.get_value("auth", "session_token", "")
		player_id = config.get_value("auth", "player_id", "")

func clear_session():
	session_token = ""
	player_id = ""
	DirAccess.remove_absolute(AUTH_SAVE_PATH)

func send_request(caller: Node, base_url: String, path: String, method: HTTPClient.Method, body: Dictionary, authenticated: bool, callback: Callable) -> void:
	var http_request := HTTPRequest.new()
	caller.add_child(http_request)

	var url := base_url + path
	var headers := PackedStringArray(["Content-Type: application/json"])
	if authenticated and is_logged_in():
		headers.append("Authorization: Bearer " + session_token)

	var body_str := ""
	if not body.is_empty():
		body_str = JSON.stringify(body)

	http_request.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, response_body: PackedByteArray):
		http_request.queue_free()
		var response := {}
		if result != HTTPRequest.RESULT_SUCCESS:
			response = {"ok": false, "status": response_code, "data": null, "error": "Connection error (result=" + str(result) + ")"}
			callback.call(response)
			return

		var ok := response_code >= 200 and response_code < 300
		var body_text := response_body.get_string_from_utf8()

		if ok and body_text.strip_edges() == "":
			response = {"ok": true, "status": response_code, "data": null, "error": ""}
			callback.call(response)
			return

		var json = JSON.parse_string(body_text)
		if json == null:
			response = {"ok": false, "status": response_code, "data": null, "error": "Invalid server response"}
			callback.call(response)
			return

		if ok:
			response = {"ok": true, "status": response_code, "data": json, "error": ""}
		else:
			var detail = json.get("detail", "Request failed") if json is Dictionary else "Request failed"
			response = {"ok": false, "status": response_code, "data": json, "error": str(detail)}
		callback.call(response)
	)

	var error := http_request.request(url, headers, method, body_str)
	if error != OK:
		http_request.queue_free()
		callback.call({"ok": false, "status": 0, "data": null, "error": "HTTP request error: " + str(error)})
