class_name DeathZoneHandler extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if multiplayer.is_server():
		self.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server(): return

	if body is PlayerController:
		body.get_node("PlayerHealth").take_damage_rpc.rpc_id(body.get_multiplayer_authority(), 100)
