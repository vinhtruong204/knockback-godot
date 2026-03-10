class_name PlayerSpawner extends MultiplayerSpawner

@export var player_scene: PackedScene
var _players_list: Dictionary[int, Node] = {}

func _ready():
	spawn_function = _spawn_player
	multiplayer.peer_connected.connect(_on_peer_connected)
	
	if multiplayer.is_server():
		set_multiplayer_authority(multiplayer.get_unique_id())
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(peer_id: int):
	if not multiplayer.is_server(): return
	
	await get_tree().create_timer(1).timeout
	var rng = RandomNumberGenerator.new()
	self.spawn({"peer_id": peer_id, "pos": Vector2(rng.randf() * 300, rng.randf() * 300)})
	
	print("spawn " + str(peer_id))

func _on_peer_disconnected(peer_id: int):
	if not multiplayer.is_server(): return
	
	var player = _players_list.get(peer_id)

	if player:
		player.queue_free()
		_players_list.erase(peer_id)

func _spawn_player(data: Dictionary) -> Node:
	var player := player_scene.instantiate()

	player.name = str(data["peer_id"])
	player.global_position = data["pos"]

	player.set_multiplayer_authority(data["peer_id"])
	_players_list[data["peer_id"]] = player
	
	return player