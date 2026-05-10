extends Node

const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_LOCALE := &"en"
const SUPPORTED := {
	&"en": "English",
	&"vi": "Tiếng Việt",
}

signal locale_changed(locale: StringName)

var current_locale: StringName = DEFAULT_LOCALE

func _ready() -> void:
	load_settings()
	TranslationServer.set_locale(String(current_locale))

func set_locale(code: StringName) -> void:
	if not SUPPORTED.has(code):
		push_warning("[LocaleManager] Unsupported locale: %s" % code)
		return
	if code == current_locale:
		return
	current_locale = code
	TranslationServer.set_locale(String(code))
	save_settings()
	locale_changed.emit(code)

func save_settings() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("locale", "current", String(current_locale))
	config.save(SETTINGS_PATH)

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	var saved := StringName(config.get_value("locale", "current", String(DEFAULT_LOCALE)))
	if SUPPORTED.has(saved):
		current_locale = saved
