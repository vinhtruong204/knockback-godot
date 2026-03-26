class_name BombController extends RigidBody2D

var _owner_id: int
@onready var explosion_area: Area2D = $ExplosionArea

func set_owner_id(id: int) -> void:
	self._owner_id = id

func _ready() -> void:
	if is_multiplayer_authority():
		get_tree().create_timer(3).timeout.connect(_on_timer_timeout)

func add_initial_impulse(direction: PlayerFlip.Direction) -> void:
	match direction:
		PlayerFlip.Direction.LEFT:
			apply_central_impulse(Vector2(-100, 0))
		PlayerFlip.Direction.RIGHT:
			apply_central_impulse(Vector2(100, 0))

func _on_timer_timeout() -> void:
	if is_multiplayer_authority():
		# Print current character in explosion area
		for body in explosion_area.get_overlapping_bodies():
			if body is CharacterBody2D:
				print(body.name)
				
		queue_free()
