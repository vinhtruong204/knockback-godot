class_name BackBtn extends Button

func _ready() -> void:
	self.pressed.connect(on_click)

func on_click():
	var parent = self.get_parent()
	
	if parent:
		parent.visible = false
