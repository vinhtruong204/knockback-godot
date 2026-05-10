class_name LanPanel extends Panel

@onready var mode_button: Button = $HBoxContainer/Panel/VBoxContainer/ModeBtn
@onready var map_button: Button = $HBoxContainer/Panel/VBoxContainer/MapBtn
@onready var team_size_button: Button = $HBoxContainer/Panel/VBoxContainer/TeamSizeBtn
@onready var host_option_button: OptionButton = $HBoxContainer/Panel2/VBoxContainer/OptionButton
@onready var host_text_edit: TextEdit = $HBoxContainer/Panel2/VBoxContainer/Host
@onready var port_text_edit: TextEdit = $HBoxContainer/Panel2/VBoxContainer/Port
@onready var start_button: Button = $HBoxContainer/Panel2/VBoxContainer/StartButton

const MAPS := ["Dust", "Forest", "Ice", "Night"]

var _selected_map_index := 0


func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	map_button.pressed.connect(_on_map_button_pressed)
	mode_button.pressed.connect(_on_mode_button_pressed)
	team_size_button.pressed.connect(_on_team_size_button_pressed)
	host_option_button.item_selected.connect(_on_host_option_selected)

	mode_button.text = tr("MODE_FREE_FOR_ALL")
	team_size_button.text = tr("MODE_1V1")
	team_size_button.disabled = true
	_update_map_button()
	host_text_edit.text = get_wifi_ip()
	port_text_edit.text = str(NetworkManager.PORT)
	_on_host_option_selected(host_option_button.selected)


func _on_start_button_pressed() -> void:
	var host = host_text_edit.text.strip_edges()
	var port_text = port_text_edit.text.strip_edges()

	if not port_text.is_valid_int():
		_show_error(tr("MM_INVALID_PORT_NAN"))
		return

	var port = port_text.to_int()
	if port < 1024 or port > 65535:
		_show_error(tr("MM_INVALID_PORT_RANGE"))
		return

	var map_name: String = MAPS[_selected_map_index]
	if host_option_button.selected == 0:
		NetworkManager.start_lan_host(port, map_name)
	else:
		if host == "" or host.begins_with("Error:"):
			_show_error(tr("MM_INVALID_HOST_IP"))
			return
		NetworkManager.start_lan_client(host, port, map_name)


func _on_map_button_pressed() -> void:
	_selected_map_index = (_selected_map_index + 1) % MAPS.size()
	_update_map_button()


func _on_mode_button_pressed() -> void:
	mode_button.text = tr("MODE_FREE_FOR_ALL")


func _on_team_size_button_pressed() -> void:
	team_size_button.text = tr("MODE_1V1")


func _on_host_option_selected(index: int) -> void:
	if index == 0:
		host_text_edit.editable = false
		if host_text_edit.text == "":
			host_text_edit.text = get_wifi_ip()
	else:
		host_text_edit.editable = true


const MAP_KEYS := ["MAP_DUST", "MAP_FOREST", "MAP_ICE", "MAP_NIGHT"]

func _update_map_button() -> void:
	map_button.text = tr(MAP_KEYS[_selected_map_index])


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

	return tr("MM_NO_WIFI_IP")


func _show_error(message: String) -> void:
	var global_ui = get_tree().root.get_node_or_null("Main/GlobalUi")
	if global_ui:
		global_ui.show_error_notification(message)
	else:
		print(message)
