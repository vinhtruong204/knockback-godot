extends Node

const ADDRESS := "100.96.156.107"
const PORT := 9543

var game_scene_path := "res://scenes/main_container/game/game.tscn"
var lobby_scene_path := "res://scenes/main_container/lobby/lobby.tscn"
var login_scene_path := "res://scenes/main_container/login/login.tscn"

# Match context — set by matchmaking before connecting, read by GameManager
var current_match_id: int = 0
var current_match_players: Array = []  # Array of {player_id, team_id} dicts
var current_player_name: String = ""
var current_map_name: String = ""


func _ready():
	if OS.has_feature("dedicated_server"):
		SceneLoader.load_scene(game_scene_path)
		create_server()
	else:
		SceneLoader.load_scene(login_scene_path)
		multiplayer.connected_to_server.connect(func():
			SceneLoader.load_scene(game_scene_path)
			)


func _on_peer_connected(id):
	print("Peer connected:", id)


func _on_peer_disconnected(id):
	print("Peer disconnected:", id)


func create_client(address: String = ADDRESS, port: int = PORT) -> void:
	var peer := ENetMultiplayerPeer.new()
	
	peer.create_client(address, port)
	multiplayer.multiplayer_peer = peer
	print("create client")
	print("create client at " + address + ":" + str(port))
	
	SceneLoader.load_scene(game_scene_path)
	get_tree().get_root().get_node("Main/GlobalUi").show_loading_screen()

func create_server(port: int = PORT) -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	print("start server at port " + str(port))
	SceneLoader.load_scene(game_scene_path)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func leave_game() -> void:
	current_match_id = 0
	current_match_players = []
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	SceneLoader.load_scene(lobby_scene_path)