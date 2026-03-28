class_name PlayerController extends CharacterBody2D

@onready var player_name: Label = $PlayerName

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Setup name for player object
	player_name.text = name
	
	# Setup color for player object
	if not is_multiplayer_authority():
		player_name.add_theme_color_override("font_color", Color.RED)
	else:
		player_name.add_theme_color_override("font_color", Color.GREEN)
	
	# Setup camera for player object
	if is_multiplayer_authority():
		$Camera2D.make_current()
		
		# Get map
		var map_sprite = get_tree().get_root().get_node("Main/SceneContainer/Game/World/MapSpawner/MapSpawnPoint/Map/Sprite2D")
		var sprite_size = map_sprite.get_rect().size

		$Camera2D.limit_left = 0 - sprite_size.x / 2
		$Camera2D.limit_right = 0 + sprite_size.x / 2
		$Camera2D.limit_top = 0 - sprite_size.y / 2
		$Camera2D.limit_bottom = 0 + sprite_size.y / 2
	else:
		$Camera2D.queue_free()


func reset() -> void:
	self.position = Vector2.ZERO

	# TODO: Reset selected gun and ammo
