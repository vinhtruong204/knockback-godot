class_name PlayerHealth extends Node

const MAX_HEALTH: int = 100
const MAX_HEART: int = 3

signal health_changed(health: int)
signal heart_changed(heart: int)
signal oponent_heart_changed(heart: int)
signal player_died(peer_id: int)
signal player_eliminated(peer_id: int)

var health: int = MAX_HEALTH:
	set(value):
		health = value

		if is_multiplayer_authority():
			health_changed.emit(health)

var heart: int = MAX_HEART:
	set(value):
		heart = value
		if is_multiplayer_authority():
			heart_changed.emit(heart)
		else:
			oponent_heart_changed.emit(heart)

@onready var player: PlayerController = $"../"

func _ready() -> void:
	if is_multiplayer_authority():
		health_changed.emit(health)
	
	# Emit event heart change both on authority and non-authority for the first time
	heart_changed.emit(heart)

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

		# Notify server of death (for kill/death tracking)
		if is_multiplayer_authority():
			_notify_server_death.rpc_id(1)

		if heart <= 0:
			heart = 0
			if is_multiplayer_authority():
				_notify_server_eliminated.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _notify_server_death() -> void:
	if not multiplayer.is_server(): return
	player_died.emit(multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_remote", "reliable")
func _notify_server_eliminated() -> void:
	if not multiplayer.is_server(): return
	player_eliminated.emit(multiplayer.get_remote_sender_id())