class_name PlayerThrowBomb extends Node

@onready var player_input: PlayerInput = $"../PlayerInput"
@onready var bomb_spawner: BombSpawner = get_tree().root.get_node("Main/SceneContainer/Game/World/BombSpawner")

func _ready() -> void:
	if is_multiplayer_authority():
		player_input.throw_bomb.connect(_on_throw_bomb)


func _on_throw_bomb() -> void:
	request_throw_bomb.rpc_id(1, multiplayer.get_unique_id(), get_parent().global_position)

@rpc("authority", "call_remote", "reliable")
func request_throw_bomb(peer_id: int, pos: Vector2) -> void:
	if not multiplayer.is_server(): return
	
	bomb_spawner.spawn({"peer_id": peer_id, "pos": pos})