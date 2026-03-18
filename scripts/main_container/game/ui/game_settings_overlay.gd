extends Control


func on_settings_pressed() -> void:
	self.show()

func on_continue_pressed() -> void:
	self.hide()

func on_leave_pressed() -> void:
	NetworkManager.leave_game()