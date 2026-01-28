extends Control

@onready var label = $"../Label"

func _on_button_server_pressed() -> void:
	NetworkHandler.start_server()
	label.text = 'Server'


func _on_button_client_pressed() -> void:
	NetworkHandler.start_client()
	label.text = 'Client'
