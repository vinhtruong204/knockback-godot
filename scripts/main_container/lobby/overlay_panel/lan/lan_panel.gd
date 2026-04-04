class_name LanPanel extends Panel

@onready var host_option_button: OptionButton = $HBoxContainer/Panel2/VBoxContainer/OptionButton
@onready var host_text_edit: TextEdit = $HBoxContainer/Panel2/VBoxContainer/Host
@onready var port_text_edit: TextEdit = $HBoxContainer/Panel2/VBoxContainer/Port
@onready var start_button: Button = $HBoxContainer/Panel2/VBoxContainer/StartButton

func _ready():
	start_button.pressed.connect(_on_start_button_pressed)
	host_text_edit.text = get_wifi_ip()
	port_text_edit.text = str(NetworkManager.PORT)

func _on_start_button_pressed():
	var host = host_text_edit.text.strip_edges()
	var port_text = port_text_edit.text.strip_edges()
	
	if not port_text.is_valid_int():
		print("Invalid port: not a number")
		return
		
	var port = port_text.to_int()
	if port < 1024 or port > 65535:
		print("Invalid port: must be between 1024 and 65535")
		return

	if host_option_button.selected == 0:
		NetworkManager.create_server(port)
		SceneLoader.load_scene(NetworkManager.game_scene_path)
		get_tree().get_root().get_node("Main/GlobalUi").show_loading_screen()
	else:
		NetworkManager.create_client(host, port)


func get_wifi_ip() -> String:
	var ips = IP.get_local_addresses()

	for ip in ips:
		if ip == "127.0.0.1":
			continue
		
		if ip.begins_with("172."):
			continue
		
		if ip.begins_with("169.254."):
			continue
		
		if ip.begins_with("100."):
			continue
		
		if ip.begins_with("192.168."):
			return ip

	return "Error: No WiFi IP found"
