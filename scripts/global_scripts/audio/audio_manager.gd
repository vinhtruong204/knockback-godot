extends Node

const SETTINGS_PATH := "user://settings.cfg"

var music_volume: float = 1.0
var sfx_volume: float = 1.0

func _ready():
	load_settings()
	apply_audio_settings()

func set_music_volume(value: float):
	music_volume = value
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(value)
	)
	save_settings()

func set_sfx_volume(value: float):
	sfx_volume = value
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		linear_to_db(value)
	)
	save_settings()

func save_settings():
	var config = ConfigFile.new()

	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)

	config.save(SETTINGS_PATH)


func load_settings():
	var config = ConfigFile.new()

	var err = config.load(SETTINGS_PATH)
	if err != OK:
		print("No settings file, using default")
		return

	music_volume = config.get_value("audio", "music_volume", 1.0)
	sfx_volume = config.get_value("audio", "sfx_volume", 1.0)

func apply_audio_settings():
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(music_volume)
	)

	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		linear_to_db(sfx_volume)
	)