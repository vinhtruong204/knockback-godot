class_name BombController extends RigidBody2D

const BOMB_FORCE: float = 100.0
const DEFAULT_DAMAGE: int = 30
const EXPLOSION_DURATION: float = 8.0 / 24.0

var _owner_id: int
var damage: int = DEFAULT_DAMAGE
var _has_exploded: bool = false

@onready var explosion_area: Area2D = $ExplosionArea
@onready var grenade_sprite: Sprite2D = $Grenade
@onready var explosion_animation: AnimatedSprite2D = $ExplosionAnimation
@onready var collision_shape_ground: CollisionShape2D = $CollisionShapeGround
@onready var collision_shape_player: CollisionShape2D = $ExplosionArea/CollisionShapePlayer

func set_owner_id(id: int) -> void:
	self._owner_id = id

func set_damage(value: int) -> void:
	if value <= 0:
		return
	damage = value

func _ready() -> void:
	if is_multiplayer_authority():
		get_tree().create_timer(3).timeout.connect(_on_timer_timeout)

func add_initial_impulse(direction: PlayerFlip.Direction) -> void:
	match direction:
		PlayerFlip.Direction.LEFT:
			apply_central_impulse(Vector2(-BOMB_FORCE, 0))
		PlayerFlip.Direction.RIGHT:
			apply_central_impulse(Vector2(BOMB_FORCE, 0))

func _on_timer_timeout() -> void:
	if not is_multiplayer_authority() or _has_exploded:
		return

	_has_exploded = true

	# Print current character in explosion area
	for body in explosion_area.get_overlapping_bodies():
		if body is PlayerController:
			print("Bomb hit:", body.name)
			var authority: int = body.get_multiplayer_authority()
			body.get_node("PlayerHealth").take_damage_rpc.rpc_id(authority, damage)

			var dir = (body.global_position - global_position).normalized()
			body.get_node("PlayerKnockback").apply_bomb_force_rpc.rpc_id(authority, dir * 150)

			_shake_player_camera(body, authority)

	play_explosion_rpc.rpc()
	await get_tree().create_timer(EXPLOSION_DURATION).timeout
	queue_free()


func _shake_player_camera(body: PlayerController, authority: int) -> void:
	if authority == multiplayer.get_unique_id():
		body.shake_camera(PlayerController.BOMB_SHAKE_STRENGTH, PlayerController.BOMB_SHAKE_DURATION)
	else:
		body.shake_camera_rpc.rpc_id(
			authority,
			PlayerController.BOMB_SHAKE_STRENGTH,
			PlayerController.BOMB_SHAKE_DURATION
		)


@rpc("authority", "call_local", "reliable")
func play_explosion_rpc() -> void:
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	freeze = true
	grenade_sprite.hide()
	collision_shape_ground.set_deferred("disabled", true)
	collision_shape_player.set_deferred("disabled", true)
	explosion_animation.show()
	explosion_animation.frame = 0
	explosion_animation.play("explode")
