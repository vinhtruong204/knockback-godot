class_name MailPanel extends Panel

const DATA_PATH := "res://scripts/main_container/lobby/overlay_panel/mail/data.json"

@onready var mail_list: VBoxContainer = $Content/HBoxContainer/ListPanel/MarginContainer/VBoxContainer/ScrollContainer/MailList
@onready var title_label: Label = $Content/HBoxContainer/DetailPanel/MarginContainer/VBoxContainer/TitleLabel
@onready var content_label: Label = $Content/HBoxContainer/DetailPanel/MarginContainer/VBoxContainer/ContentLabel
@onready var rewards_container: VBoxContainer = $Content/HBoxContainer/DetailPanel/MarginContainer/VBoxContainer/RewardsScroll/RewardsContainer
@onready var claim_button: Button = $Content/HBoxContainer/DetailPanel/MarginContainer/VBoxContainer/ClaimBtn

var _mails: Array = []
var _selected_index := -1
var _claim_in_progress := false


func _ready() -> void:
	claim_button.pressed.connect(_on_claim_pressed)
	_load_mails()
	_render_mail_list()
	if _mails.size() > 0:
		_select_mail(0)
	else:
		_show_empty_state()


func _load_mails() -> void:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("[MailPanel] Missing mail data: " + DATA_PATH)
		_mails = []
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		_mails = parsed
	elif parsed is Dictionary:
		_mails = [parsed]
	else:
		push_error("[MailPanel] Invalid mail data")
		_mails = []


func _render_mail_list() -> void:
	for child in mail_list.get_children():
		child.queue_free()

	for i in range(_mails.size()):
		var mail: Dictionary = _mails[i]
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 56)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.theme_type_variation = &"PanelButton"
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = _format_mail_button_text(mail)
		button.pressed.connect(_select_mail.bind(i))
		mail_list.add_child(button)


func _format_mail_button_text(mail: Dictionary) -> String:
	var prefix := "[Claimed] " if bool(mail.get("claimed", false)) else ""
	return prefix + str(mail.get("title", "Admin Mail"))


func _select_mail(index: int) -> void:
	if index < 0 or index >= _mails.size():
		return

	_selected_index = index
	var mail: Dictionary = _mails[index]
	title_label.text = str(mail.get("title", "Admin Mail"))
	content_label.text = str(mail.get("content", ""))
	_render_rewards(mail.get("rewards", []))
	_refresh_claim_button(mail)


func _show_empty_state() -> void:
	title_label.text = "No mail"
	content_label.text = "There are no admin mails right now."
	_render_rewards([])
	claim_button.disabled = true
	claim_button.text = "Claim"


func _render_rewards(rewards: Array) -> void:
	for child in rewards_container.get_children():
		child.queue_free()

	for reward in rewards:
		if not (reward is Dictionary):
			continue
		rewards_container.add_child(_create_reward_row(reward))


func _create_reward_row(reward: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 44)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 10)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(36, 36)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _get_reward_texture(reward)
	row.add_child(icon)

	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text = _format_reward_text(reward)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)

	return row


func _get_reward_texture(reward: Dictionary) -> Texture2D:
	var reward_type := str(reward.get("type", ""))
	if reward_type == "currency":
		var currency_type := str(reward.get("currency_type", "gold"))
		var currency_path := "res://assets/lobby/top_bar/currency/%s.png" % currency_type
		if ResourceLoader.exists(currency_path):
			return load(currency_path)

	var image_name := str(reward.get("image", ""))
	var item_type := str(reward.get("item_type", ""))
	if item_type == Enums.ItemType.WEAPON and image_name != "":
		var weapon_path := "res://assets/game/weapon/static/%s" % image_name
		if ResourceLoader.exists(weapon_path):
			return load(weapon_path)
	elif item_type == Enums.ItemType.CHARACTER and image_name != "":
		var character_path := "res://assets/game/player/%s" % image_name
		if ResourceLoader.exists(character_path):
			return load(character_path)

	return null


func _format_reward_text(reward: Dictionary) -> String:
	if str(reward.get("type", "")) == "currency":
		return "%d %s" % [int(reward.get("amount", 0)), str(reward.get("currency_type", "")).capitalize()]

	var name := str(reward.get("name", "Reward"))
	var item_type := str(reward.get("item_type", "item")).capitalize()
	return "%s - %s" % [name, item_type]


func _refresh_claim_button(mail: Dictionary) -> void:
	if _claim_in_progress:
		claim_button.disabled = true
		claim_button.text = "Claiming..."
		return

	var claimed := bool(mail.get("claimed", false))
	claim_button.disabled = claimed
	claim_button.text = "Claimed" if claimed else "Claim"


func _on_claim_pressed() -> void:
	if _selected_index < 0 or _selected_index >= _mails.size() or _claim_in_progress:
		return

	var mail: Dictionary = _mails[_selected_index]
	if bool(mail.get("claimed", false)):
		return

	_finish_claim(true)


func _finish_claim(success: bool) -> void:
	_claim_in_progress = false
	if _selected_index < 0 or _selected_index >= _mails.size():
		return

	var mail: Dictionary = _mails[_selected_index]
	var global_ui := _get_global_ui()
	if success:
		mail["claimed"] = true
		_render_mail_list()
		_select_mail(_selected_index)
		if global_ui:
			global_ui.show_reward_notification(str(mail.get("title", "Admin Mail")), _get_reward_count(mail), "reward")
	else:
		_refresh_claim_button(mail)
		if global_ui:
			global_ui.show_error_notification("Claim failed")


func _get_reward_count(mail: Dictionary) -> int:
	var rewards: Array = mail.get("rewards", [])
	return max(1, rewards.size())


func _get_global_ui() -> GlobalUI:
	var main := get_tree().root.get_node_or_null("Main")
	if main:
		return main.get_node_or_null("GlobalUi") as GlobalUI
	return get_tree().root.get_node_or_null("GlobalUi") as GlobalUI
