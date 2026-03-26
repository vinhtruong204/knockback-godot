class_name PlayerThrowBomb extends Node

@onready var player_input: PlayerInput = $"../PlayerInput"
@onready var bomb_spawner: BombSpawner = get_tree().root.get_node("Main/SceneContainer/Game/World/BombSpawner")
@onready var bomb_barrel: Node2D = $BombBarrel
@onready var player_flip: PlayerFlip = $"../PlayerFlip"

func _ready() -> void:
	if is_multiplayer_authority():
		player_input.throw_bomb.connect(_on_throw_bomb)


func _on_throw_bomb() -> void:
	var bomb_barrel_position: Vector2 = Vector2()
	var direction: PlayerFlip.Direction = player_flip.get_player_direction()

	match direction:
		PlayerFlip.Direction.LEFT:
			bomb_barrel_position = get_parent().global_position - bomb_barrel.position
		PlayerFlip.Direction.RIGHT:
			bomb_barrel_position = get_parent().global_position + bomb_barrel.position

	request_throw_bomb.rpc_id(1, multiplayer.get_unique_id(), bomb_barrel_position, direction)


@rpc("authority", "call_remote", "reliable")
func request_throw_bomb(peer_id: int, pos: Vector2, direction: PlayerFlip.Direction) -> void:
	if not multiplayer.is_server(): return
	
	bomb_spawner.spawn({"peer_id": peer_id, "pos": pos, "direction": direction})
