extends Node

const CACHE_DIR := "user://cache/"

# TTL presets in seconds
const TTL_STATIC := 3600.0 # 1 hour - config data (weapons, characters, maps, modes, etc.)
const TTL_SEMI := 300.0 # 5 minutes - shop items, player profile/stats
const TTL_DYNAMIC := 30.0 # 30 seconds - currency, inventory, equipment


class CacheEntry:
	var data: Variant
	var timestamp: float
	var ttl: float
	var category: String
	var persist: bool

	func is_expired() -> bool:
		return Time.get_unix_time_from_system() - timestamp >= ttl


var _cache: Dictionary = {}
var _dirty_categories: Dictionary = {}


func _ready() -> void:
	_ensure_cache_dir()
	# Force the first data read in each app session to hit the backend.
	clear_all()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_flush_dirty()


# --- Read ---

func get_data(key: String) -> Variant:
	if _cache.has(key):
		var entry: CacheEntry = _cache[key]
		if not entry.is_expired():
			return entry.data
		_cache.erase(key)
	return null


func has_valid(key: String) -> bool:
	if _cache.has(key):
		var entry: CacheEntry = _cache[key]
		if not entry.is_expired():
			return true
		_cache.erase(key)
	return false


func get_entry(key: String) -> CacheEntry:
	if _cache.has(key):
		var entry: CacheEntry = _cache[key]
		if not entry.is_expired():
			return entry
		_cache.erase(key)
	return null


# --- Write ---

func set_data(key: String, data: Variant, ttl: float, category: String, persist: bool = false) -> void:
	var entry := CacheEntry.new()
	entry.data = data
	entry.timestamp = Time.get_unix_time_from_system()
	entry.ttl = ttl
	entry.category = category
	entry.persist = persist
	_cache[key] = entry

	if persist:
		_dirty_categories[category] = true
		call_deferred("_flush_dirty")


# --- Invalidation ---

func invalidate(key: String) -> void:
	if _cache.has(key):
		var entry: CacheEntry = _cache[key]
		if entry.persist:
			_dirty_categories[entry.category] = true
			call_deferred("_flush_dirty")
		_cache.erase(key)


func invalidate_category(category: String) -> void:
	var keys_to_remove: Array[String] = []
	for key in _cache:
		var entry: CacheEntry = _cache[key]
		if entry.category == category:
			keys_to_remove.append(key)
	
	for key in keys_to_remove:
		_cache.erase(key)
	
	if _dirty_categories.has(category):
		_dirty_categories.erase(category)

	# Remove disk file for this category
	var path := CACHE_DIR + category + ".json"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func invalidate_player(pid: String) -> void:
	var keys_to_remove: Array[String] = []
	for key in _cache:
		if key.contains(pid):
			keys_to_remove.append(key)
	for key in keys_to_remove:
		_cache.erase(key)


func clear_all() -> void:
	_cache.clear()
	_dirty_categories.clear()
	# Remove all disk cache files
	var dir := DirAccess.open(CACHE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				DirAccess.remove_absolute(CACHE_DIR + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()


# --- High-level: fetch or return cached ---

func fetch_or_cache(key: String, ttl: float, category: String, persist: bool, fetch_fn: Callable, callback: Callable) -> void:
	var entry := get_entry(key)
	if entry != null:
		_call_if_valid(callback, {"ok": true, "status": 200, "data": entry.data, "error": ""})
		return

	fetch_fn.call(func(response: Dictionary):
		if response.get("ok", false):
			set_data(key, response.get("data"), ttl, category, persist)
		_call_if_valid(callback, response)
	)


func _call_if_valid(callback: Callable, response: Dictionary) -> void:
	if callback.is_valid():
		callback.call(response)


# --- Disk Persistence ---

func save_to_disk() -> void:
	_ensure_cache_dir()
	var categories: Dictionary = {}
	for key in _cache:
		var entry: CacheEntry = _cache[key]
		if not entry.persist or entry.is_expired():
			continue
		if not categories.has(entry.category):
			categories[entry.category] = {}
		categories[entry.category][key] = {
			"data": entry.data,
			"timestamp": entry.timestamp,
			"ttl": entry.ttl,
		}

	for category in categories:
		var path = CACHE_DIR + category + ".json"
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(categories[category]))
			file.close()


func load_from_disk() -> void:
	var dir := DirAccess.open(CACHE_DIR)
	if not dir:
		return
	var now := Time.get_unix_time_from_system()
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			var category := file_name.get_basename()
			var path := CACHE_DIR + file_name
			var file := FileAccess.open(path, FileAccess.READ)
			if file:
				var content := file.get_as_text()
				file.close()
				var parsed = JSON.parse_string(content)
				if parsed is Dictionary:
					for key in parsed:
						var item = parsed[key]
						if not item is Dictionary:
							continue
						
						var timestamp: float = item.get("timestamp", 0.0)
						var ttl: float = item.get("ttl", 0.0)
						# Skip expired or future-timestamped entries
						if now - timestamp >= ttl or timestamp > now + 60.0:
							continue
						var entry := CacheEntry.new()
						entry.data = item.get("data")
						entry.timestamp = timestamp
						entry.ttl = ttl
						entry.category = category
						entry.persist = true
						_cache[key] = entry
		file_name = dir.get_next()
	dir.list_dir_end()


func _ensure_cache_dir() -> void:
	if not DirAccess.dir_exists_absolute(CACHE_DIR):
		DirAccess.make_dir_recursive_absolute(CACHE_DIR)


func _flush_dirty() -> void:
	if _dirty_categories.is_empty():
		return
	
	_ensure_cache_dir()
	
	# Group current valid entries by category for only the dirty ones
	var data_to_save: Dictionary = {} # category -> { key -> item_dict }
	for category in _dirty_categories:
		data_to_save[category] = {}
	
	for key in _cache:
		var entry: CacheEntry = _cache[key]
		if entry.persist and _dirty_categories.has(entry.category) and not entry.is_expired():
			data_to_save[entry.category][key] = {
				"data": entry.data,
				"timestamp": entry.timestamp,
				"ttl": entry.ttl,
			}
	
	for category in data_to_save:
		var entries: Dictionary = data_to_save[category]
		var path = CACHE_DIR + category + ".json"
		
		if entries.is_empty():
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
		else:
			var file := FileAccess.open(path, FileAccess.WRITE)
			if file:
				file.store_string(JSON.stringify(entries))
				file.close()
				
	_dirty_categories.clear()
