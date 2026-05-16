class_name OpponentInfor extends Panel


@export var player_spawner: PlayerSpawner

@onready var opponent_name: Label = $Name
@onready var opponent_heart_number: Label = $HeartNumber

func _ready() -> void:
	player_spawner.player_spawned.connect(_on_player_spawned)

func _on_player_spawned(player: Node) -> void:
	var health_node: PlayerHealth = player.get_node_or_null("PlayerHealth") as PlayerHealth

	if player.get_multiplayer_authority() != multiplayer.get_unique_id() and health_node:
		opponent_name.text = _format_opponent_name(player)
		opponent_heart_number.text = str(health_node.heart)

		if not health_node.oponent_heart_changed.is_connected(_on_heart_changed):
			health_node.oponent_heart_changed.connect(_on_heart_changed)

func _on_heart_changed(heart: int) -> void:
	opponent_heart_number.text = str(heart)


func _format_opponent_name(player: Node) -> String:
	var display_name := str(player.get_meta("display_name", player.name))
	var team_id := int(player.get_meta("team_id", 0))
	if NetworkManager.is_search_destroy_mode():
		if team_id == 1:
			return "[PLANT] " + display_name
		if team_id == 2:
			return "[DEFUSE] " + display_name
	return display_name
