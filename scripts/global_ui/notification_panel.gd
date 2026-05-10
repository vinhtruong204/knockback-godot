class_name NotificationPanel extends PanelContainer

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var content_label: Label = $VBoxContainer/ContentLabel
@onready var price_container: HBoxContainer = $VBoxContainer/PriceContainer
@onready var ok_button: Button = $VBoxContainer/OkButton


func _ready() -> void:
	ok_button.pressed.connect(_on_ok_pressed)


func show_purchase(item_type: String, _price: int, _currency_type: String) -> void:
	title_label.text = tr("NOTIF_PURCHASE_SUCCESS")
	content_label.text = tr("NOTIF_PURCHASE_BODY_FMT") % item_type.capitalize()
	price_container.visible = true


func show_reward(item_name: String, amount: int, currency_type: String) -> void:
	title_label.text = tr("NOTIF_REWARD_CLAIMED")
	content_label.text = tr("NOTIF_REWARD_BODY_FMT") % [item_name, amount, currency_type.capitalize()]
	price_container.visible = false


func show_error(message: String) -> void:
	title_label.text = tr("NOTIF_ERROR")
	content_label.text = message
	price_container.visible = false


func _on_ok_pressed() -> void:
	get_parent().visible = false
