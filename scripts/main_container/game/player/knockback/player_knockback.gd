class_name PlayerKnockback extends Node

@onready var player_movement: PlayerMovement = $"../PlayerMovement"
@onready var player_health: PlayerHealth = $"../PlayerHealth"

@rpc("any_peer", "call_remote", "reliable")
func apply_knockback_rpc(direction: int, force: float):
	if not is_multiplayer_authority(): return
	
	var dir = Vector2.ZERO

	match direction:
		PlayerFlip.Direction.LEFT:
			dir = Vector2.LEFT
		PlayerFlip.Direction.RIGHT:
			dir = Vector2.RIGHT

	player_movement.knockback_velocity += dir * force

@rpc("any_peer", "call_remote", "reliable")
func apply_bomb_force_rpc(force: Vector2):
	if not is_multiplayer_authority(): return

	player_movement.knockback_velocity += force