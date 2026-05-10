class_name SettingsController extends Panel

@onready var music_slider: HSlider = $VBoxContainer/MusicContainer/HSlider
@onready var sfx_slider: HSlider = $VBoxContainer/SoundContainer/HSlider
@onready var en_btn: Button = $VBoxContainer/LanguageContainer/HBoxContainer/EnBtn
@onready var vi_btn: Button = $VBoxContainer/LanguageContainer/HBoxContainer/ViBtn

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_configure_audio_slider(music_slider)
	_configure_audio_slider(sfx_slider)

	# Get current audio settings
	music_slider.value = AudioManager.music_volume
	sfx_slider.value = AudioManager.sfx_volume

	# Connect signals
	music_slider.value_changed.connect(_on_music_slider_value_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_value_changed)

	en_btn.pressed.connect(func(): LocaleManager.set_locale(&"en"))
	vi_btn.pressed.connect(func(): LocaleManager.set_locale(&"vi"))
	LocaleManager.locale_changed.connect(_refresh_locale_buttons)
	_refresh_locale_buttons(LocaleManager.current_locale)

func _refresh_locale_buttons(code: StringName) -> void:
	en_btn.disabled = (code == &"en")
	vi_btn.disabled = (code == &"vi")

func _on_music_slider_value_changed(value: float) -> void:
	AudioManager.set_music_volume(value)

func _on_sfx_slider_value_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value)

func _configure_audio_slider(slider: HSlider) -> void:
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01

func _on_low_fps_button_pressed() -> void:
	Engine.max_fps = 30

func _on_medium_fps_button_pressed() -> void:
	Engine.max_fps = 45

func _on_high_fps_button_pressed() -> void:
	Engine.max_fps = 60
