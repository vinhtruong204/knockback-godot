class_name ConfirmationContainer extends PanelContainer

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var content_label: Label = $VBoxContainer/ContentLabel
@onready var confirm_button: Button = $VBoxContainer/HBoxContainer/ConfirmButton
@onready var cancel_button: Button = $VBoxContainer/HBoxContainer/CancelButton

var _on_confirm: Callable


func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)


func show_confirm(item_type: String, price: int, currency_type: String, on_confirm: Callable) -> void:
	_on_confirm = on_confirm
	title_label.text = "Confirm Purchase"
	content_label.text = "Buy %s for %d %s?" % [item_type.capitalize(), price, currency_type.capitalize()]


func _on_confirm_pressed() -> void:
	get_parent().visible = false
	if _on_confirm.is_valid():
		_on_confirm.call()


func _on_cancel_pressed() -> void:
	get_parent().visible = false
