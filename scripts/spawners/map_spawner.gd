extends MultiplayerSpawner

const MAX_PLAYER = 2;
var _current_player = 0;
@export var map_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not multiplayer.is_server(): return

	spawn_function = _spawn_map

	self.set_multiplayer_authority(multiplayer.get_unique_id())

	multiplayer.peer_connected.connect(_on_peer_connected)

func _on_peer_connected(_peer_id: int):
	if not multiplayer.is_server(): return

	_current_player += 1
	
	if _current_player == MAX_PLAYER:
		self.spawn()

func _spawn_map(_data) -> Node2D:
	var map = map_scene.instantiate()

	map.set_multiplayer_authority(multiplayer.get_unique_id())

	return map
