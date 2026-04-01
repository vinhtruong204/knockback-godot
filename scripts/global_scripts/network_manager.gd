extends Node

const ADDRESS := "localhost"
const PORT := 9543
var game_scene_path := "res://scenes/main_container/game/game.tscn"
var lobby_scene_path := "res://scenes/main_container/lobby/lobby.tscn"
var login_scene_path := "res://scenes/main_container/login/login.tscn"

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

func create_client() -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_client(ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer

	print("create client")

	SceneLoader.load_scene(game_scene_path)
	get_tree().get_root().get_node("Main/GlobalUi").show_loading_screen()

func create_server() -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer

	print("start server at " + ADDRESS + ":" + str(PORT))

	SceneLoader.load_scene(game_scene_path)

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func leave_game() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	SceneLoader.load_scene(lobby_scene_path)
