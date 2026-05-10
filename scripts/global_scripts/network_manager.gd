extends Node

const ADDRESS := "100.96.156.107"
const PORT := 9543
const GAME_MODE_RANK := "rank"
const GAME_MODE_NORMAL := "normal"
const GAME_MODE_LAN := "lan"

var game_scene_path := "res://scenes/main_container/game/game.tscn"
var lobby_scene_path := "res://scenes/main_container/lobby/lobby.tscn"
var login_scene_path := "res://scenes/main_container/login/login.tscn"

var current_match_id: int = 0
var current_match_players: Array = []
var current_player_name: String = ""
var current_map_name: String = ""
var current_map_key: String = ""
var current_game_mode: String = GAME_MODE_RANK
var is_lan_host_player: bool = false


func _ready() -> void:
	if OS.has_feature("dedicated_server"):
		SceneLoader.load_scene(game_scene_path)
		create_server(PORT, false)
	else:
		SceneLoader.load_scene(login_scene_path)
		multiplayer.connected_to_server.connect(func():
			if SceneLoader.scene_path != game_scene_path:
				SceneLoader.load_scene(game_scene_path)
		)
		multiplayer.connection_failed.connect(func():
			var global_ui = get_tree().root.get_node_or_null("Main/GlobalUi")
			if global_ui:
				global_ui.show_error_notification(tr("NETWORK_CONNECT_FAIL"))
			leave_game()
		)


func _on_peer_connected(id: int) -> void:
	print("Peer connected:", id)


func _on_peer_disconnected(id: int) -> void:
	print("Peer disconnected:", id)


func start_online_match(match_context: Dictionary) -> void:
	current_game_mode = str(match_context.get("game_mode", GAME_MODE_RANK))
	current_match_id = int(match_context.get("match_id", 0))
	current_match_players = match_context.get("players", [])
	current_map_name = str(match_context.get("map_name", ""))
	current_map_key = str(match_context.get("map_key", get_map_key(current_map_name)))
	is_lan_host_player = false
	create_client(str(match_context.get("address", ADDRESS)), int(match_context.get("port", PORT)))


func start_lan_host(port: int, map_name: String = "") -> void:
	current_game_mode = GAME_MODE_LAN
	current_match_id = 0
	current_match_players = []
	current_map_name = map_name
	current_map_key = get_map_key(map_name)
	is_lan_host_player = true
	create_server(port)


func start_lan_client(address: String, port: int, map_name: String = "") -> void:
	current_game_mode = GAME_MODE_LAN
	current_match_id = 0
	current_match_players = []
	current_map_name = map_name
	current_map_key = get_map_key(map_name)
	is_lan_host_player = false
	create_client(address, port)


func create_client(address: String = ADDRESS, port: int = PORT) -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		var global_ui = get_tree().root.get_node_or_null("Main/GlobalUi")
		if global_ui:
			global_ui.show_error_notification(tr("NETWORK_CLIENT_ERR_PREFIX") + str(err))
		return

	multiplayer.multiplayer_peer = peer
	print("create client")
	print("create client at " + address + ":" + str(port))

	SceneLoader.load_scene(game_scene_path)
	get_tree().get_root().get_node("Main/GlobalUi").show_loading_screen()


func create_server(port: int = PORT, load_game_scene: bool = true) -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port)
	if err != OK:
		var global_ui = get_tree().root.get_node_or_null("Main/GlobalUi")
		if global_ui:
			global_ui.show_error_notification(tr("NETWORK_SERVER_ERR_PREFIX") + str(port))
		return

	multiplayer.multiplayer_peer = peer
	print("start server at port " + str(port))
	if load_game_scene:
		SceneLoader.load_scene(game_scene_path)
		get_tree().get_root().get_node("Main/GlobalUi").show_loading_screen()
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func leave_game() -> void:
	AudioManager.play_music(&"lobby")
	current_match_id = 0
	current_match_players = []
	current_map_name = ""
	current_map_key = ""
	current_game_mode = GAME_MODE_RANK
	is_lan_host_player = false
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	SceneLoader.load_scene(lobby_scene_path)


func get_map_key(map_name: String) -> String:
	var normalized := map_name.strip_edges().to_lower().replace("_", " ").replace("-", " ")
	match normalized:
		"night", "nightmare", "nuke":
			return "night"
		"ice", "mirage":
			return "ice"
		"dust", "dust ii", "dust2":
			return "dust"
		"forest", "inferno":
			return "forest"
		_:
			return normalized.replace(" ", "")
