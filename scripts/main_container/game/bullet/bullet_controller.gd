class_name BulletController extends Area2D

const BULLET_SPEED: float = 100.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if is_multiplayer_authority():
		get_tree().create_timer(4.0).timeout.connect(queue_free)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_multiplayer_authority(): return

	# Move bullet
	position.x += BULLET_SPEED * delta