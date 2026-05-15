class_name PlayerController extends CharacterBody2D

const DEFAULT_GRENADE_DAMAGE: int = 30

const BOMB_SHAKE_STRENGTH: float = 8.0
const BOMB_SHAKE_DURATION: float = 0.3

const CAMERA_BASE_ZOOM: Vector2 = Vector2.ONE
const CAMERA_FRAME_MARGIN: Vector2 = Vector2(220.0, 160.0)
const CAMERA_POSITION_SMOOTH_SPEED: float = 6.0
const CAMERA_ZOOM_SMOOTH_SPEED: float = 5.0
const CAMERA_OPPONENT_WEIGHT: float = 0.5
const CAMERA_MIN_ZOOM_FALLBACK: float = 0.35

@onready var player_name: Label = $PlayerName
@onready var character_sprite: Sprite2D = $ChracterSprites/CharacterBody/Sprite2D

var grenade_damage: int = DEFAULT_GRENADE_DAMAGE

var _camera: Camera2D
var _opponent: PlayerController
var _camera_min_zoom: float = CAMERA_MIN_ZOOM_FALLBACK
var _camera_limits_ready: bool = false
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
		_camera.zoom = CAMERA_BASE_ZOOM
		_camera.make_current()
		_setup_camera_limits()
	else:
		$Camera2D.queue_free()


func _process(delta: float) -> void:
	if _camera != null:
		if not _camera_limits_ready:
			_setup_camera_limits()
		_update_camera_framing(delta)

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


func _setup_camera_limits() -> void:
	var map_sprite: Sprite2D = get_tree().get_root().get_node_or_null("Main/SceneContainer/Game/World/MapSpawner/MapSpawnPoint/Map/Sprite2D") as Sprite2D
	if map_sprite == null:
		return

	var rect: Rect2 = map_sprite.get_rect()
	var top_left: Vector2 = map_sprite.to_global(rect.position)
	var bottom_right: Vector2 = map_sprite.to_global(rect.position + rect.size)
	var map_left: float = minf(top_left.x, bottom_right.x)
	var map_right: float = maxf(top_left.x, bottom_right.x)
	var map_top: float = minf(top_left.y, bottom_right.y)
	var map_bottom: float = maxf(top_left.y, bottom_right.y)
	var map_size: Vector2 = Vector2(map_right - map_left, map_bottom - map_top)
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		return

	_camera.limit_left = floori(map_left)
	_camera.limit_right = ceili(map_right)
	_camera.limit_top = floori(map_top)
	_camera.limit_bottom = ceili(map_bottom)
	_camera_limits_ready = true

	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var fit_map_zoom: float = minf(viewport_size.x / map_size.x, viewport_size.y / map_size.y)
	_camera_min_zoom = clampf(fit_map_zoom, 0.05, CAMERA_BASE_ZOOM.x)


func _update_camera_framing(delta: float) -> void:
	var opponent: PlayerController = _get_opponent()
	var target_global_position: Vector2 = global_position
	var target_zoom_value: float = CAMERA_BASE_ZOOM.x

	if opponent != null:
		target_global_position = global_position.lerp(opponent.global_position, CAMERA_OPPONENT_WEIGHT)
		target_zoom_value = _calculate_framing_zoom(global_position, opponent.global_position)

	var target_camera_position: Vector2 = target_global_position - global_position
	var position_weight: float = clampf(delta * CAMERA_POSITION_SMOOTH_SPEED, 0.0, 1.0)
	var zoom_weight: float = clampf(delta * CAMERA_ZOOM_SMOOTH_SPEED, 0.0, 1.0)

	_camera.position = _camera.position.lerp(target_camera_position, position_weight)
	_camera.zoom = _camera.zoom.lerp(Vector2(target_zoom_value, target_zoom_value), zoom_weight)


func _get_opponent() -> PlayerController:
	if _is_valid_opponent(_opponent):
		return _opponent

	_opponent = null
	var spawn_parent: Node = get_parent()
	if spawn_parent == null:
		return null

	for child in spawn_parent.get_children():
		if _is_valid_opponent(child):
			_opponent = child as PlayerController
			return _opponent

	return null


func _is_valid_opponent(node: Variant) -> bool:
	if not is_instance_valid(node) or node == self or not (node is PlayerController):
		return false

	var player: PlayerController = node as PlayerController
	return player.is_inside_tree() and player.get_multiplayer_authority() != multiplayer.get_unique_id()


func _calculate_framing_zoom(first_position: Vector2, second_position: Vector2) -> float:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return CAMERA_BASE_ZOOM.x

	var required_size: Vector2 = Vector2(
		absf(first_position.x - second_position.x),
		absf(first_position.y - second_position.y)
	) + CAMERA_FRAME_MARGIN * 2.0

	var zoom_x: float = viewport_size.x / maxf(required_size.x, 1.0)
	var zoom_y: float = viewport_size.y / maxf(required_size.y, 1.0)
	var target_zoom: float = minf(CAMERA_BASE_ZOOM.x, minf(zoom_x, zoom_y))
	return clampf(target_zoom, _camera_min_zoom, CAMERA_BASE_ZOOM.x)


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
