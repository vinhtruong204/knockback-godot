extends MultiplayerSpawner

@export var player_scene: PackedScene

func _ready():
	spawn_function = _spawn_player
	
	if multiplayer.is_server():
		set_multiplayer_authority(multiplayer.get_unique_id())
		multiplayer.peer_connected.connect(_on_peer_connected)

func _on_peer_connected(peer_id: int):
	if multiplayer.is_server():
		spawn(peer_id)

func _spawn_player(peer_id: int) -> Node:
	var player = player_scene.instantiate()
	player.name = str(peer_id)
	player.set_multiplayer_authority(peer_id)
	return player
