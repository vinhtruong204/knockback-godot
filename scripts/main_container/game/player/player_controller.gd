class_name PlayerController extends CharacterBody2D

const DEFAULT_GRENADE_DAMAGE: int = 30

@onready var player_name: Label = $PlayerName
@onready var character_sprite: Sprite2D = $ChracterSprites/CharacterBody/Sprite2D

var grenade_damage: int = DEFAULT_GRENADE_DAMAGE


func set_character_texture(tex: Texture2D) -> void:
	if tex == null:
		return
	character_sprite.texture = tex


func set_grenade_damage(value: int) -> void:
	if value <= 0:
		return
	grenade_damage = value

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Display name from PlayerSpawner metadata; falls back to the node name
	# (the peer_id string) when no spawn-time name was provided (instant-start).
	player_name.text = get_meta("display_name", name)

	# Character sprite texture stashed by PlayerSpawner. Applied here because
	# character_sprite is @onready and is null until the node enters the tree.
	# _ready runs before _physics_process, so the sprite is in place before
	# the player ever falls.
	var texture_name: String = get_meta("character_texture_name", "")
	if texture_name != "":
		var tex = load("res://assets/game/player/" + texture_name)
		if tex:
			set_character_texture(tex)

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

	var wh = get_node_or_null("ChracterSprites/WeaponHoldHandler")
	if wh and wh.has_method("reset_ammo_and_active"):
		wh.reset_ammo_and_active()
