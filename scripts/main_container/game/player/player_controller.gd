class_name PlayerController extends CharacterBody2D

const DEFAULT_GRENADE_DAMAGE: int = 30

const BOMB_SHAKE_STRENGTH: float = 8.0
const BOMB_SHAKE_DURATION: float = 0.3

@onready var player_name: Label = $PlayerName
@onready var character_sprite: Sprite2D = $ChracterSprites/CharacterBody/Sprite2D

var grenade_damage: int = DEFAULT_GRENADE_DAMAGE

var _camera: Camera2D
var _shake_strength: float = 0.0
var _shake_duration: float = 0.0
var _shake_time_left: float = 0.0


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
		_camera = $Camera2D
		_camera.make_current()

		# Get map
		var map_sprite = get_tree().get_root().get_node("Main/SceneContainer/Game/World/MapSpawner/MapSpawnPoint/Map/Sprite2D")
		var sprite_size = map_sprite.get_rect().size

		_camera.limit_left = 0 - sprite_size.x / 2
		_camera.limit_right = 0 + sprite_size.x / 2
		_camera.limit_top = 0 - sprite_size.y / 2
		_camera.limit_bottom = 0 + sprite_size.y / 2
	else:
		$Camera2D.queue_free()


func _process(delta: float) -> void:
	if _shake_time_left > 0.0 and _camera != null:
		_shake_time_left = max(_shake_time_left - delta, 0.0)
		var t: float = _shake_time_left / _shake_duration
		var amp: float = _shake_strength * t
		if _shake_time_left == 0.0:
			_camera.offset = Vector2.ZERO
		else:
			_camera.offset = Vector2(
				randf_range(-amp, amp),
				randf_range(-amp, amp)
			)


func shake_camera(strength: float, duration: float) -> void:
	if _camera == null or duration <= 0.0:
		return
	_shake_strength = strength
	_shake_duration = duration
	_shake_time_left = duration


@rpc("any_peer", "call_local", "unreliable")
func shake_camera_rpc(strength: float, duration: float) -> void:
	shake_camera(strength, duration)


func reset() -> void:
	self.position = Vector2.ZERO

	var wh = get_node_or_null("ChracterSprites/WeaponHoldHandler")
	if wh and wh.has_method("reset_ammo_and_active"):
		wh.reset_ammo_and_active()
