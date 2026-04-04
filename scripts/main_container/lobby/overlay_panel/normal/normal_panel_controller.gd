class_name NormalPanelController extends Panel

@onready var map_btn: Button = $Panel/VBoxContainer/MapBtn
@onready var popup_choose_map: Panel = $PopupChooseMap
@onready var close_btn: Button = $PopupChooseMap/Panel/CloseBtn
@onready var mode_btn: Button = $Panel/VBoxContainer/ModeBtn
@onready var team_size_btn: Button = $Panel/VBoxContainer/TeamSizeBtn
@onready var fight_btn: Button = $Panel/VBoxContainer/FightBtn

func _ready() -> void:
	map_btn.pressed.connect(_on_map_btn_pressed)
	close_btn.pressed.connect(_on_close_btn_pressed)
	mode_btn.pressed.connect(_on_mode_btn_pressed)
	team_size_btn.pressed.connect(_on_team_size_btn_pressed)
	fight_btn.pressed.connect(_on_fight_btn_pressed)

func _on_map_btn_pressed() -> void:
	popup_choose_map.show()

func _on_close_btn_pressed() -> void:
	popup_choose_map.hide()

func _on_map_selected(map: String) -> void:
	popup_choose_map.hide()
	map_btn.text = map

func _on_mode_btn_pressed() -> void:
	# change the text switch between free for all and search and destroy
	if mode_btn.text == "Free for all":
		mode_btn.text = "Search & Destroy"
	else:
		mode_btn.text = "Free for all"

func _on_team_size_btn_pressed() -> void:
	# change the text switch between 1v1 and 2v2
	if team_size_btn.text == "1v1":
		team_size_btn.text = "2v2"
	else:
		team_size_btn.text = "1v1"

func _on_fight_btn_pressed() -> void:
	# TODO: call the api to create a match
	pass
