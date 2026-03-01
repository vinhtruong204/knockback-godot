class_name GlobalUI extends CanvasLayer

var scene_path := "res://scenes/main_container/lobby/lobby.tscn"
@onready var progress_bar := $LoadingContainer/LoadingProgressBar
var is_loaded := false

func _ready():
	ResourceLoader.load_threaded_request(scene_path)

func _process(_delta):
	if is_loaded:
		return

	var progress = []
	var status := ResourceLoader.load_threaded_get_status(scene_path, progress)

	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			progress_bar.value = progress[0] * 100.0

		ResourceLoader.THREAD_LOAD_LOADED:
			progress_bar.value = progress[0] * 100.0
			is_loaded = true

			#await get_tree().create_timer(1).timeout # delay 1 second 
			var packed_scene = ResourceLoader.load_threaded_get(scene_path)
			var scene = packed_scene.instantiate()
			get_parent().get_node("SceneContainer").add_child(scene)

			$LoadingContainer.visible = false
