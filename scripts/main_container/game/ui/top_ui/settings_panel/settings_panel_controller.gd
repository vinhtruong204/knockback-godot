class_name SettingsPanelController extends Panel


@export var player_spawner: PlayerSpawner
@onready var health_bar: TextureProgressBar = $HealthBar
@onready var heart_number: Label = $HeartNumber

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_spawner.player_spawned.connect(_on_player_spawned)

func _on_player_spawned(player: Node) -> void:
	var health_node = player.get_node("PlayerHealth")

	if player.get_multiplayer_authority() == multiplayer.get_unique_id() and health_node:
		health_node.heart_changed.connect(_on_heart_changed)
		health_node.health_changed.connect(_on_health_changed)
		health_node.max_health_changed.connect(_on_max_health_changed)
		health_bar.max_value = health_node.MAX_HEALTH

func _on_heart_changed(heart: int) -> void:
	heart_number.text = str(heart)

func _on_health_changed(health: int) -> void:
	health_bar.value = health

func _on_max_health_changed(max_health: int) -> void:
	health_bar.max_value = max_health
