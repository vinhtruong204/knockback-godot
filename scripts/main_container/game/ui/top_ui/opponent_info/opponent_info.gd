class_name OpponentInfor extends Panel


@export var player_spawner: PlayerSpawner

@onready var opponent_name: Label = $Name
@onready var opponent_heart_number: Label = $HeartNumber

func _ready() -> void:
	player_spawner.player_spawned.connect(_on_player_spawned)

func _on_player_spawned(player: Node) -> void:
	var health_node = player.get_node("PlayerHealth")

	if player.get_multiplayer_authority() != multiplayer.get_unique_id() and health_node:
		# Set opponent player name
		opponent_name.text = player.name

		health_node.oponent_heart_changed.connect(_on_heart_changed)

func _on_heart_changed(heart: int) -> void:
	opponent_heart_number.text = str(heart)
