extends MultiplayerSpawner

const MAX_PLAYER = 2;
var _current_player = 0;
@export var player_scene: PackedScene

@export var players_id: Array[int]

func _ready():
	if multiplayer.is_server():
		set_multiplayer_authority(multiplayer.get_unique_id())

		spawn_function = _spawn_player
		multiplayer.peer_connected.connect(_on_peer_connected)

func _on_peer_connected(peer_id: int):
	if not multiplayer.is_server(): return

	players_id.append(peer_id)

	_current_player += 1
	
	if _current_player == MAX_PLAYER and multiplayer.is_server():
		for id in range(_current_player):
			self.spawn({"peer_id": players_id[id], "pos": Vector2(id * 100, 0)})

func _spawn_player(data: Dictionary) -> Node:
	var player = player_scene.instantiate()

	player.name = str(data["peer_id"])
	player.global_position = data["pos"]

	player.set_multiplayer_authority(data["peer_id"])
	
	return player
