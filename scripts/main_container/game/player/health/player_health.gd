class_name PlayerHealth extends Node

const DEFAULT_MAX_HEALTH: int = 100
const MAX_HEART: int = 5

var MAX_HEALTH: int = DEFAULT_MAX_HEALTH

signal health_changed(health: int)
signal heart_changed(heart: int)
signal oponent_heart_changed(heart: int)
signal max_health_changed(max_health: int)
signal player_died(peer_id: int)
signal player_eliminated(peer_id: int)

var health: int = DEFAULT_MAX_HEALTH:
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
	# Apply HP stashed by PlayerSpawner. Done here (not in the spawner) because
	# set_max_health writes to `health`, whose setter calls is_multiplayer_authority(),
	# which is illegal until the node is inside the tree.
	var pending_max_health := int(get_meta("pending_max_health", 0))
	if pending_max_health > 0:
		set_max_health(pending_max_health)

	if is_multiplayer_authority():
		health_changed.emit(health)

	# Emit event heart change both on authority and non-authority for the first time
	heart_changed.emit(heart)


func set_max_health(value: int) -> void:
	if value <= 0:
		return
	MAX_HEALTH = value
	max_health_changed.emit(MAX_HEALTH)
	# Setter on `health` re-emits health_changed for authority
	health = value

@rpc("any_peer", "call_remote", "reliable")
func take_damage_rpc(damage: int) -> void:
	if not is_multiplayer_authority(): return

	health -= damage
	AudioManager.play_sfx(&"character_hit")

	if health <= 0:
		# Reset health and decrease heart
		health = MAX_HEALTH
		heart -= 1

		# Reset position
		player.reset()

		# Notify server of death (for kill/death tracking)
		_notify_death()

		if heart <= 0:
			heart = 0
			_notify_eliminated()


func _notify_death() -> void:
	if multiplayer.is_server():
		player_died.emit(player.get_multiplayer_authority())
	elif is_multiplayer_authority():
		_notify_server_death.rpc_id(1)


func _notify_eliminated() -> void:
	if multiplayer.is_server():
		player_eliminated.emit(player.get_multiplayer_authority())
	elif is_multiplayer_authority():
		_notify_server_eliminated.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _notify_server_death() -> void:
	if not multiplayer.is_server(): return
	player_died.emit(multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_remote", "reliable")
func _notify_server_eliminated() -> void:
	if not multiplayer.is_server(): return
	player_eliminated.emit(multiplayer.get_remote_sender_id())
