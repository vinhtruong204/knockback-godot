class_name PlayerHealth extends Node

const MAX_HEALTH: int = 50
const MAX_HEART: int = 2

@export var health: int = MAX_HEALTH
@export var heart: int = MAX_HEART

@onready var player: PlayerController = $"../"

@rpc("any_peer", "call_remote", "reliable")
func take_damage_rpc(damage: int) -> void:
	if not is_multiplayer_authority(): return

	health -= damage

	if health <= 0:
		# Reset health and decrease heart
		health = MAX_HEALTH
		heart -= 1

		# Reset position
		player.reset()
		
		if heart <= 0:
			heart = 0
			# get_parent().visible = false
			
			# TODO: Add respawn system (rpc call to server to reset pos(value))