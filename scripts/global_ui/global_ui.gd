class_name GlobalUI extends CanvasLayer

@onready var progress_bar := $LoadingContainer/LoadingProgressBar
@onready var loading_container := $LoadingContainer
@onready var notification_container := $NotificationContainer
@onready var notification_panel: NotificationPanel = $NotificationContainer/NotificationPanel
@onready var confirm_container := $ConfirmContainer
@onready var confirm_dialog: ConfirmationContainer = $ConfirmContainer/ConfirmationContainer
@onready var item_detail_container := $ItemDetailContainer
@onready var item_detail_panel: ItemDetailPanel = $ItemDetailContainer/ItemDetailPanel

var is_loaded: bool = false

func _ready():
	if not OS.has_feature("dedicated_server"):
		is_loaded = false

func _process(_delta):
	if is_loaded:
		return

	var progress: float = SceneLoader.get_progress() * 100.0
	progress_bar.value = progress
	
	if progress == 100.0:
		loading_container.visible = false
		is_loaded = true


func show_loading_screen() -> void:
	loading_container.visible = true
	is_loaded = false
	progress_bar.value = 0.0


func show_purchase_notification(item_type: String, price: int, currency_type: String) -> void:
	notification_panel.show_purchase(item_type, price, currency_type)
	notification_container.visible = true


func show_reward_notification(item_name: String, amount: int, currency_type: String) -> void:
	notification_panel.show_reward(item_name, amount, currency_type)
	notification_container.visible = true


func show_error_notification(message: String) -> void:
	notification_panel.show_error(message)
	notification_container.visible = true


func show_confirm_purchase(item_type: String, price: int, currency_type: String, on_confirm: Callable) -> void:
	confirm_dialog.show_confirm(item_type, price, currency_type, on_confirm)
	confirm_container.visible = true


func show_item_detail(item_id: int, item_type: String, price: int, currency_type: String, on_buy: Callable, is_owned: bool, discount: float = 0.0) -> void:
	item_detail_panel.show_detail(item_id, item_type, price, currency_type, on_buy, is_owned, discount)
	item_detail_container.visible = true
