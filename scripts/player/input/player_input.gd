extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if is_multiplayer_authority() and Input.is_action_just_pressed("player_shoot"):
		var pos = $"../Muzzle".global_position
		rpc_id(1, "request_fire", pos)

# SERVER
@rpc("any_peer", "reliable")
func request_fire(pos: Vector2):
	if !multiplayer.is_server():
		return

	spawn_bullet(pos)

func spawn_bullet(pos: Vector2):
	var spawner := get_node("/root/Main/BulletSpawner")
	spawner.spawn(pos)
