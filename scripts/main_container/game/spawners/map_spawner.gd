class_name MapSpawner extends MultiplayerSpawner

const MAP_TEXTURE_PATH := "res://assets/game/map/"
const DEFAULT_MAP := "dust"

@export var map_scene: PackedScene

func _enter_tree() -> void:
	self.spawn_function = _spawn_map

func _ready() -> void:
	if multiplayer.is_server():
		self.set_multiplayer_authority(multiplayer.get_unique_id())
		$"../PlayerSpawner".all_player_joined.connect(_on_all_player_joined)

func _on_all_player_joined() -> void:
	print("All player joined")
	# Get map name from GameManager
	var game_manager = get_tree().root.get_node_or_null("Main/SceneContainer/Game") as GameManager
	var map_texture_name := DEFAULT_MAP
	if game_manager and game_manager.map_name != "":
		map_texture_name = game_manager.map_name.to_lower()
	spawn({"map_texture_name": map_texture_name})

func _spawn_map(data: Dictionary) -> Node:
	var map = map_scene.instantiate()

	if multiplayer.is_server():
		map.set_multiplayer_authority(multiplayer.get_unique_id())

	# Set map texture
	var texture_name: String = data.get("map_texture_name", DEFAULT_MAP)
	var texture_path := MAP_TEXTURE_PATH + texture_name + ".png"
	var texture = load(texture_path)
	if texture:
		var sprite: Sprite2D = map.get_node_or_null("Sprite2D")
		if sprite:
			sprite.texture = texture
	print("Map spawned: " + texture_name)

	return map