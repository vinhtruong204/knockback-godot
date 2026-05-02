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
	bullet.direction = data["direction"]
	bullet.owner_id = data["peer_id"]
	bullet.damage = int(data.get("damage", BulletController.DEFAULT_DAMAGE))

	return bullet