extends Node

var current_scene: Node = null
var scene_path: String = ""
var is_loaded := false
var _progress: Array[float] = [0.0]

func get_progress() -> float:
	return _progress[0]

func _ready() -> void:
	pass

func load_scene(path: String):
	# Clean up old scene
	if current_scene:
		current_scene.queue_free()
		current_scene = null
		await get_tree().process_frame
	
	# Reset loaded variable
	is_loaded = false
	scene_path = path

	# Load new scene
	ResourceLoader.load_threaded_request(path)


func _process(_delta):
	if self.is_loaded:
		return

	var status := ResourceLoader.load_threaded_get_status(scene_path, _progress)

	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			_progress = [1.0]
			var packed_scene = ResourceLoader.load_threaded_get(scene_path)
			
			var scene = packed_scene.instantiate()
			current_scene = scene
			is_loaded = true

			var container = get_tree().root.get_node("Main/SceneContainer")
			container.add_child(scene)