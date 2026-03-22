class_name BulletSpawner extends MultiplayerSpawner

@export var bullet_scene: PackedScene

func _ready() -> void:
	spawn_function = _spawn_bullet

	if multiplayer.is_server():
		set_multiplayer_authority(multiplayer.get_unique_id())

	
func _spawn_bullet(data: Dictionary) -> Node:
	var bullet := bullet_scene.instantiate()

	if multiplayer.is_server():
		bullet.set_multiplayer_authority(multiplayer.get_unique_id())
		
	bullet.name = str(data["peer_id"])
	bullet.global_position = data["pos"]
	return bullet