class_name TransitionLayer extends CanvasLayer

@onready var _animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	await fade_in()
	await fade_out()

func fade_out() -> void:
	_animation_player.play(FadeAnimation.FADE_OUT)
	await _animation_player.animation_finished

func fade_in() -> void:
	_animation_player.play(FadeAnimation.FADE_IN)
	await _animation_player.animation_finished
