class_name FightButtonHandler extends Button

func _on_fight_pressed():
    NetworkManager.create_client()

func _on_server_pressed():
    NetworkManager.create_server()