class_name GlobalUI extends CanvasLayer

@onready var progress_bar := $LoadingContainer/LoadingProgressBar
var is_loaded: bool = false

func _ready():
	if not OS.has_feature("dedicated_server"):
		is_loaded = false

func _process(_delta):
	if is_loaded:
		return

	var progress: float = SceneLoader.get_progress() * 100.0
	progress_bar.value = progress
	
	if progress == 100.0:
		$LoadingContainer.visible = false
		is_loaded = true
