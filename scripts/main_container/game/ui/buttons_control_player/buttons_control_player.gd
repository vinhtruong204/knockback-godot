class_name ButtonsControlPlayer extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$JumpBtn.pressed.connect(_on_jump_btn_pressed)
	$AttackBtn.pressed.connect(_on_attack_btn_pressed)
	$BombBtn.pressed.connect(_on_bomb_btn_pressed)

func _on_jump_btn_pressed() -> void:
	Input.action_press("player_jump")
	Input.action_release("player_jump")

func _on_attack_btn_pressed() -> void:
	Input.action_press("player_attack")
	Input.action_release("player_attack")

func _on_bomb_btn_pressed() -> void:
	Input.action_press("player_bomb")
	Input.action_release("player_bomb")
