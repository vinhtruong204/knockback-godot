class_name BombController extends RigidBody2D

const BOMB_FORCE: float = 100.0
const DEFAULT_DAMAGE: int = 30

var _owner_id: int
var damage: int = DEFAULT_DAMAGE
@onready var explosion_area: Area2D = $ExplosionArea

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
	if is_multiplayer_authority():
		# Print current character in explosion area
		for body in explosion_area.get_overlapping_bodies():
			if body is PlayerController:
				print("Bomb hit:", body.name)
				body.get_node("PlayerHealth").take_damage_rpc.rpc_id(body.get_multiplayer_authority(), damage)

				var dir = (body.global_position - global_position).normalized()
				body.get_node("PlayerKnockback").apply_bomb_force_rpc.rpc_id(body.get_multiplayer_authority(), dir * 150)
				
		queue_free()
