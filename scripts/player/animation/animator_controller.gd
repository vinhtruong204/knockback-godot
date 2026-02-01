class_name AnimatorController extends Node2D

@onready var animation: AnimatedSprite2D = $"../AnimatedSprite2D"
var _current_animation = 'idle'

func _ready() -> void:
	# play default animation
	change_animation(_current_animation)
	
func change_animation(new_animation_name: String):
	if (_current_animation == new_animation_name): return
	
	animation.play(new_animation_name)
	_current_animation = new_animation_name


func _on_state_machine_state_change(new_state_name: String) -> void:
	change_animation(new_state_name)
