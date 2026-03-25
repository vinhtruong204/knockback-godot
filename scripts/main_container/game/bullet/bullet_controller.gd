class_name BulletController extends Area2D

const BULLET_SPEED: float = 200.0
var direction: PlayerFlip.Direction
var owner_id: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if multiplayer.is_server():
		get_tree().create_timer(4.0).timeout.connect(queue_free)

		match direction:
			PlayerFlip.Direction.LEFT:
				$Sprite2D.flip_h = true
			PlayerFlip.Direction.RIGHT:
				$Sprite2D.flip_h = false

		self.body_entered.connect(_on_body_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if not multiplayer.is_server(): return

	# Move bullet
	match direction:
		PlayerFlip.Direction.LEFT:
			position.x -= BULLET_SPEED * delta
		PlayerFlip.Direction.RIGHT:
			position.x += BULLET_SPEED * delta

func _on_body_entered(body: Node) -> void:
	if not multiplayer.is_server(): return

	if body.get_multiplayer_authority() != owner_id:
		print("Hit:", body.name)

		# body.get_node("PlayerKnockback").apply_knockback_rpc.rpc_id(body.get_multiplayer_authority(), direction, 200.0)
		body.get_node("PlayerHealth").take_damage_rpc.rpc_id(body.get_multiplayer_authority(), 50)
		self.queue_free()
