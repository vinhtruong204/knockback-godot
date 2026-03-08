extends Node

const ADDRESS := "127.0.0.1"
const PORT := 9543
var game_scene_path := "res://scenes/main_container/game/game.tscn"

func _ready():
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)

    multiplayer.connected_to_server.connect(func():
        SceneLoader.load_scene(game_scene_path)
        )

func _on_peer_connected(id):
    print("Peer connected:", id)

    # spawn some character on server

func _on_peer_disconnected(id):
    print("Peer disconnected:", id)

func create_client() -> void:
    var peer := ENetMultiplayerPeer.new()
    peer.create_client(ADDRESS, PORT)
    multiplayer.multiplayer_peer = peer

    print("create client")

func create_server() -> void:
    var peer := ENetMultiplayerPeer.new()
    peer.create_server(PORT)
    multiplayer.multiplayer_peer = peer

    print("create server")

    SceneLoader.load_scene(game_scene_path)