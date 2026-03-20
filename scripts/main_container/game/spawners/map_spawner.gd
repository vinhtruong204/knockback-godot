class_name MapSpawner extends MultiplayerSpawner

@export var map_scene: PackedScene

func _enter_tree() -> void:
	self.spawn_function = _spawn_map

func _ready() -> void:
	if multiplayer.is_server():
		self.set_multiplayer_authority(multiplayer.get_unique_id())
		$"../PlayerSpawner".all_player_joined.connect(_on_all_player_joined)

func _on_all_player_joined() -> void:
	print("All player joined")
	spawn({})

func _spawn_map(_data: Dictionary) -> Node:
	var map = map_scene.instantiate()
	
	if multiplayer.is_server():
		map.set_multiplayer_authority(multiplayer.get_unique_id())
		print("Map spawned")

	return map