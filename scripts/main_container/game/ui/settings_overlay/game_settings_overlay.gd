class_name GameSettingsOverlay extends Control

@onready var music_slider: HSlider = $SettingsPanel/VBoxContainer/Music/HSlider
@onready var sfx_slider: HSlider = $SettingsPanel/VBoxContainer/Sound/HSlider


func _ready() -> void:
	_configure_audio_slider(music_slider)
	_configure_audio_slider(sfx_slider)

	music_slider.value = AudioManager.music_volume
	sfx_slider.value = AudioManager.sfx_volume

	music_slider.value_changed.connect(_on_music_slider_value_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_value_changed)


func on_settings_pressed() -> void:
	music_slider.value = AudioManager.music_volume
	sfx_slider.value = AudioManager.sfx_volume
	self.show()

func on_continue_pressed() -> void:
	self.hide()

func on_leave_pressed() -> void:
	NetworkManager.leave_game()

func _on_music_slider_value_changed(value: float) -> void:
	AudioManager.set_music_volume(value)

func _on_sfx_slider_value_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value)

func _configure_audio_slider(slider: HSlider) -> void:
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
