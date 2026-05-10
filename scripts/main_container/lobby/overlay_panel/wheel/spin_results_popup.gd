extends PanelContainer

@onready var grid_container: GridContainer = $VBoxContainer/ScrollContainer/GridContainer
@onready var ok_button: Button = $VBoxContainer/OkButton


func _ready() -> void:
	ok_button.pressed.connect(_on_ok_pressed)


func show_results(results: Array, wheel_type: String) -> void:
	# Clear previous entries
	for child in grid_container.get_children():
		child.queue_free()

	for result in results:
		var entry := _create_result_entry(result, wheel_type)
		grid_container.add_child(entry)

	visible = true


func _create_result_entry(result: Dictionary, wheel_type: String) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(200, 30)

	# Icon
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var image_name: String = result.get("image", "")
	var item_type: String = str(result.get("item_type", ""))

	if item_type == "weapon" and image_name != "":
		var path := "res://assets/game/weapon/static/%s" % image_name
		if ResourceLoader.exists(path):
			icon.texture = load(path)
	elif item_type == "character" and image_name != "":
		var path := "res://assets/game/player/%s" % image_name
		if ResourceLoader.exists(path):
			icon.texture = load(path)
	else:
		var path := "res://assets/lobby/top_bar/currency/%s.png" % wheel_type
		if ResourceLoader.exists(path):
			icon.texture = load(path)

	hbox.add_child(icon)

	# Info column
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	name_label.text = result.get("display_name", tr("COMMON_UNKNOWN"))
	name_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(name_label)

	var status_label := Label.new()
	status_label.add_theme_font_size_override("font_size", 8)

	var is_duplicate: bool = result.get("is_duplicate", false)
	var compensation: int = int(result.get("compensation_amount", 0))
	var currency_reward = result.get("currency_reward")

	if is_duplicate:
		status_label.text = tr("WHEEL_DUPLICATE_FMT") % [compensation, wheel_type.capitalize()]
		status_label.add_theme_color_override("font_color", Color(1, 0.85, 0))
	elif currency_reward != null:
		status_label.text = tr("WHEEL_REWARD_FMT") % [int(currency_reward), wheel_type.capitalize()]
		status_label.add_theme_color_override("font_color", Color(0.6, 0.85, 1))
	else:
		status_label.text = tr("COMMON_NEW")
		status_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))

	vbox.add_child(status_label)
	hbox.add_child(vbox)

	return hbox


func _on_ok_pressed() -> void:
	queue_free()
