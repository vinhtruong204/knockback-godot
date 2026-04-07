class_name NotificationPanel extends PanelContainer

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var content_label: Label = $VBoxContainer/ContentLabel
@onready var price_container: HBoxContainer = $VBoxContainer/PriceContainer
@onready var ok_button: Button = $VBoxContainer/OkButton


func _ready() -> void:
	ok_button.pressed.connect(_on_ok_pressed)


func show_purchase(item_type: String, _price: int, _currency_type: String) -> void:
	title_label.text = "Purchase Successful!"
	content_label.text = "You bought a %s" % item_type.capitalize()
	price_container.visible = true


func show_reward(item_name: String, amount: int, currency_type: String) -> void:
	title_label.text = "Reward Claimed!"
	content_label.text = "%s\n+%d %s" % [item_name, amount, currency_type.capitalize()]
	price_container.visible = false


func show_error(message: String) -> void:
	title_label.text = "Error"
	content_label.text = message
	price_container.visible = false


func _on_ok_pressed() -> void:
	get_parent().visible = false
