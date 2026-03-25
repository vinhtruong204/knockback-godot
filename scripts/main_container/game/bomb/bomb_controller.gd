class_name BombController extends Node2D

var _owner_id: int

func set_owner_id(id: int) -> void:
	self._owner_id = id

func _ready() -> void:
	if is_multiplayer_authority():
		get_tree().create_timer(3).timeout.connect(queue_free)
