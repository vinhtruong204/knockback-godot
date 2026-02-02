extends MultiplayerSpawner

@export var bullet_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	spawn_function = _spawn_bullet
	
	if multiplayer.is_server():
		set_multiplayer_authority(multiplayer.get_unique_id())

func _spawn_bullet(pos: Vector2) -> Node:
	var bullet = bullet_scene.instantiate()

	bullet.global_position = pos

	bullet.set_multiplayer_authority(1)

	return bullet
