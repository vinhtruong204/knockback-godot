class_name PlayerAttack extends Node

@onready var player: CharacterBody2D = $"../"
@onready var gun_barrel: Node2D = $GunBarrel
@onready var player_input: PlayerInput = $"../PlayerInput"
@onready var player_flip: PlayerFlip = $"../PlayerFlip"
@onready var bullet_spawner: BulletSpawner

func _ready() -> void:
	# Separate get node for bullet spawner (Because bullet spawner is in different scene)
	# IMPORTANT: Bullet only spawn in server, only need reference to bullet spawner in server
	if multiplayer.is_server():
		bullet_spawner = get_tree().root.get_node("Main/SceneContainer/Game/World/BulletSpawner")

	if is_multiplayer_authority():
		player_input.shoot.connect(_on_shoot)


func _on_shoot() -> void:
	# Calculate gun barrel position based on player direction
	var gun_barrel_position: Vector2 = Vector2()
	var direction: PlayerFlip.Direction = player_flip.get_player_direction()

	match direction:
		PlayerFlip.Direction.LEFT:
			gun_barrel_position = player.global_position - gun_barrel.position
		PlayerFlip.Direction.RIGHT:
			gun_barrel_position = player.global_position + gun_barrel.position

	request_shoot.rpc_id(1, multiplayer.get_unique_id(), gun_barrel_position, direction)


@rpc("authority", "call_remote", "reliable")
func request_shoot(peer_id: int, pos: Vector2, direction: PlayerFlip.Direction) -> void:
	if not multiplayer.is_server(): return
	
	bullet_spawner.spawn({"peer_id": peer_id, "pos": pos, "direction": direction})
