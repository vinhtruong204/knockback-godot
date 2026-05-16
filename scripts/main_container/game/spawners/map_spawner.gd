class_name MapSpawner extends MultiplayerSpawner

signal map_spawned(map: Node)

const MAP_TEXTURE_PATH := "res://assets/game/map/"
const DEFAULT_MAP := "dust"
const PLATFORM_SCENE_PATHS := {
	"night": "res://scenes/main_container/game/map/platforms/night_platforms.tscn",
	"ice": "res://scenes/main_container/game/map/platforms/ice_platforms.tscn",
	"dust": "res://scenes/main_container/game/map/platforms/dust_platforms.tscn",
	"forest": "res://scenes/main_container/game/map/platforms/forest_platforms.tscn",
}

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
	var map_key := DEFAULT_MAP
	if game_manager and game_manager.map_name != "":
		map_key = NetworkManager.get_map_key(game_manager.map_name)
	spawn({"map_texture_name": map_key})

func _spawn_map(data: Dictionary) -> Node:
	var map = map_scene.instantiate()

	if multiplayer.is_server():
		map.set_multiplayer_authority(multiplayer.get_unique_id())

	var map_key := _get_supported_map_key(str(data.get("map_texture_name", DEFAULT_MAP)))

	# Set map texture
	var texture_path := MAP_TEXTURE_PATH + map_key + ".png"
	var texture = load(texture_path)
	if texture:
		var sprite: Sprite2D = map.get_node_or_null("Sprite2D")
		if sprite:
			sprite.texture = texture

	_spawn_platforms(map, map_key)
	print("Map spawned: " + map_key)
	map_spawned.emit(map)

	return map


func _get_supported_map_key(map_name: String) -> String:
	var map_key := NetworkManager.get_map_key(map_name)
	if PLATFORM_SCENE_PATHS.has(map_key):
		return map_key
	return DEFAULT_MAP


func _spawn_platforms(map: Node, map_key: String) -> void:
	var platforms_parent := map.get_node_or_null("Platforms") as Node2D
	if not platforms_parent:
		platforms_parent = Node2D.new()
		platforms_parent.name = "Platforms"
		map.add_child(platforms_parent)

	for child in platforms_parent.get_children():
		child.queue_free()

	var platform_scene_path: String = PLATFORM_SCENE_PATHS.get(map_key, PLATFORM_SCENE_PATHS[DEFAULT_MAP])
	var platform_scene := load(platform_scene_path) as PackedScene
	if not platform_scene:
		print("Missing platform scene: ", platform_scene_path, "; falling back to ", DEFAULT_MAP)
		platform_scene = load(PLATFORM_SCENE_PATHS[DEFAULT_MAP]) as PackedScene
		if not platform_scene:
			return

	platforms_parent.add_child(platform_scene.instantiate())
