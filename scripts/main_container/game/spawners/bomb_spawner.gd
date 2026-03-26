class_name BombSpawner extends MultiplayerSpawner

@export var bomb_scene: PackedScene

func _ready():
	spawn_function = _spawn_bomb

	if multiplayer.is_server():
		set_multiplayer_authority(multiplayer.get_unique_id())
		

func _spawn_bomb(data: Dictionary) -> Node:
	var bomb := bomb_scene.instantiate()

	if multiplayer.is_server():
		bomb.set_multiplayer_authority(multiplayer.get_unique_id())
		bomb.global_position = data["pos"]
		bomb.set_owner_id(data["peer_id"])
		bomb.add_initial_impulse(data["direction"])
	
	return bomb
