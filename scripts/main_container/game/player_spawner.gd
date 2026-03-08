class_name PlayerSpawner extends MultiplayerSpawner

@export var player_scene: PackedScene

func _ready():
	spawn_function = _spawn_player

	if multiplayer.is_server():
		set_multiplayer_authority(multiplayer.get_unique_id())

		multiplayer.peer_connected.connect(_on_peer_connected)

func _on_peer_connected(peer_id: int):
	if not multiplayer.is_server(): return
	
	var rng = RandomNumberGenerator.new()
	self.spawn({"peer_id": peer_id, "pos": Vector2(rng.randf() * 300, rng.randf() * 300)})
	
	print("spawn " + str(peer_id))

func _spawn_player(data: Dictionary) -> Node:
	var player = player_scene.instantiate()

	player.name = str(data["peer_id"])
	player.global_position = data["pos"]

	player.set_multiplayer_authority(data["peer_id"])
	
	return player