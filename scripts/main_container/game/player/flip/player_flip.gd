class_name PlayerFlip extends Node

enum Direction {
	LEFT,
	RIGHT
}

@onready var player_input: PlayerInput = $"../PlayerInput"
@onready var character_sprite: Node2D = $"../ChracterSprites"

var _player_direction: Direction = Direction.LEFT

func get_player_direction() -> Direction:
	return _player_direction

func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority() or not player_input: return
	
	var dir := player_input.get_dir()
	
	if dir.x > 0:
		character_sprite.scale.x = -1
		_player_direction = Direction.RIGHT
	elif dir.x < 0:
		character_sprite.scale.x = 1
		_player_direction = Direction.LEFT
