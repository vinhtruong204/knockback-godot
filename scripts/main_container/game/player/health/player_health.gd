class_name PlayerHealth extends Node

const MAX_HEALTH: int = 100
const MAX_HEART: int = 3

signal health_changed(health: int)
signal heart_changed(heart: int)
signal oponent_heart_changed(heart: int)

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
		
		if heart <= 0:
			heart = 0
			# get_parent().visible = false
			
			# TODO: Add respawn system (rpc call to server to reset pos(value))