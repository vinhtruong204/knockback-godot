extends Node

const SETTINGS_PATH := "user://settings.cfg"
const MIN_VOLUME_DB := -80.0
const SFX_POOL_SIZE := 8

const MUSIC_TRACKS := {
	&"lobby": preload("res://assets/audio/background_music/lobby/music_background.mp3"),
	&"ingame": preload("res://assets/audio/background_music/in_game/ingame_background.mp3"),
}

const SFX_SOUNDS := {
	&"button_click": preload("res://assets/audio/background_music/lobby/button_clicked.ogg"),
	&"character_jump": preload("res://assets/audio/sfx/characater/jump.ogg"),
	&"character_hit": preload("res://assets/audio/sfx/characater/hit.ogg"),
	&"character_run": preload("res://assets/audio/sfx/characater/run.ogg"),
	&"primary_shoot": preload("res://assets/audio/sfx/weapon/primary/primary_shoot.ogg"),
	&"primary_reload": preload("res://assets/audio/sfx/weapon/primary/primary_reload.ogg"),
	&"secondary_shoot": preload("res://assets/audio/sfx/weapon/secondary/secondary_shoot.ogg"),
	&"secondary_reload": preload("res://assets/audio/sfx/weapon/secondary/secondary_reload.ogg"),
	&"melee_stabbing": preload("res://assets/audio/sfx/weapon/melee/melee_stabbing.ogg"),
	&"throw_bomb": preload("res://assets/audio/sfx/weapon/bomb/throw_bomb.ogg"),
	&"explode": preload("res://assets/audio/sfx/weapon/bomb/explode.ogg"),
	&"lucky_wheel_ting": preload("res://assets/audio/sfx/lucky_wheel/ting.ogg"),
	&"lucky_wheel_reward": preload("res://assets/audio/sfx/lucky_wheel/reward.ogg"),
}

const OPTIONAL_SFX_PATHS := {
	&"sd_planted": "res://assets/audio/sfx/objective/search_destroy/planted.ogg",
	&"sd_bomb_tick": "res://assets/audio/sfx/objective/search_destroy/bomb_tick.ogg",
	&"sd_defuse": "res://assets/audio/sfx/objective/search_destroy/defuse.ogg",
	&"sd_explosion": "res://assets/audio/sfx/objective/search_destroy/explosion.ogg",
}

var music_volume: float = 1.0
var sfx_volume: float = 1.0
var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _current_music_track: StringName = &""
var _missing_optional_sfx_warned: Dictionary = {}
var _optional_sfx_cache: Dictionary = {}

func _ready():
	_setup_players()
	_preload_optional_sfx()
	load_settings()
	apply_audio_settings()

func set_music_volume(value: float):
	music_volume = clampf(value, 0.0, 1.0)
	_set_bus_volume("Music", music_volume)
	save_settings()

func set_sfx_volume(value: float):
	sfx_volume = clampf(value, 0.0, 1.0)
	_set_bus_volume("SFX", sfx_volume)
	save_settings()

func play_music(track: StringName, restart := false) -> void:
	if not MUSIC_TRACKS.has(track):
		push_warning("[AudioManager] Unknown music track: %s" % track)
		return
	if _current_music_track == track and _music_player.playing and not restart:
		return

	var stream := MUSIC_TRACKS[track] as AudioStream
	if stream == null:
		push_warning("[AudioManager] Invalid music stream: %s" % track)
		return

	_current_music_track = track
	_music_player.stop()
	_music_player.stream = _make_looping_stream(stream)
	_music_player.play()

func stop_music() -> void:
	_current_music_track = &""
	if _music_player:
		_music_player.stop()

func play_sfx(sound: StringName) -> void:
	var stream: AudioStream = null
	if SFX_SOUNDS.has(sound):
		stream = SFX_SOUNDS[sound] as AudioStream
	elif OPTIONAL_SFX_PATHS.has(sound):
		if _optional_sfx_cache.has(sound):
			stream = _optional_sfx_cache[sound] as AudioStream
		else:
			stream = _load_optional_sfx(sound)
			if stream == null:
				return
	else:
		push_warning("[AudioManager] Unknown SFX sound: %s" % sound)
		return

	if stream == null:
		push_warning("[AudioManager] Invalid SFX stream: %s" % sound)
		return

	var player := _get_available_sfx_player()
	player.stop()
	player.stream = stream
	player.play()

func bind_button_sfx(root: Node) -> void:
	_bind_button_sfx_recursive(root)

func save_settings():
	var config = ConfigFile.new()
	config.load(SETTINGS_PATH)

	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)

	config.save(SETTINGS_PATH)


func load_settings():
	var config = ConfigFile.new()

	var err = config.load(SETTINGS_PATH)
	if err != OK:
		print("No settings file, using default")
		return

	music_volume = clampf(float(config.get_value("audio", "music_volume", 1.0)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value("audio", "sfx_volume", 1.0)), 0.0, 1.0)

func apply_audio_settings():
	_set_bus_volume("Music", music_volume)
	_set_bus_volume("SFX", sfx_volume)

func _setup_players() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Music"
	_music_player.finished.connect(_on_music_finished)
	add_child(_music_player)

	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer%d" % i
		player.bus = "SFX"
		add_child(player)
		_sfx_players.append(player)


func _preload_optional_sfx() -> void:
	for sound_key in OPTIONAL_SFX_PATHS.keys():
		_load_optional_sfx(StringName(str(sound_key)))


func _load_optional_sfx(sound: StringName) -> AudioStream:
	var path: String = str(OPTIONAL_SFX_PATHS[sound])
	if not ResourceLoader.exists(path):
		if not _missing_optional_sfx_warned.has(sound):
			_missing_optional_sfx_warned[sound] = true
			push_warning("[AudioManager] Optional SFX not installed yet: %s" % path)
		return null
	var stream: AudioStream = load(path) as AudioStream
	if stream != null:
		_optional_sfx_cache[sound] = stream
	return stream


func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			return player
	return _sfx_players[0]

func _make_looping_stream(stream: AudioStream) -> AudioStream:
	var playback_stream := stream.duplicate()
	if playback_stream is AudioStreamMP3:
		playback_stream.loop = true
	return playback_stream

func _on_music_finished() -> void:
	if _current_music_track != &"":
		play_music(_current_music_track, true)

func _set_bus_volume(bus_name: String, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("[AudioManager] Missing audio bus: %s" % bus_name)
		return
	var db := MIN_VOLUME_DB if value <= 0.0 else linear_to_db(value)
	AudioServer.set_bus_volume_db(bus_index, db)

func _bind_button_sfx_recursive(node: Node) -> void:
	if node is BaseButton and not node.pressed.is_connected(_on_button_sfx_pressed):
		node.pressed.connect(_on_button_sfx_pressed)
	for child in node.get_children():
		_bind_button_sfx_recursive(child)

func _on_button_sfx_pressed() -> void:
	play_sfx(&"button_click")
