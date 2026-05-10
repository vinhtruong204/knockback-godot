class_name PurchaseController extends Panel

@onready var currency_ui: CurrencyContainer = %UIButtons/TopBar/CurrencyContainer
@onready var _grid: GridContainer = $GridContainer

var _pending_sku: String = ""


func _ready() -> void:
	BillingService.purchase_succeeded.connect(_on_purchase_succeeded)
	BillingService.purchase_failed.connect(_on_purchase_failed)
	BillingService.purchase_cancelled.connect(_on_purchase_cancelled)


func on_purchase_button_pressed(sku: String) -> void:
	if _pending_sku != "":
		return
	_pending_sku = sku
	_set_buttons_disabled(true)
	BillingService.purchase(sku)


func _on_purchase_succeeded(sku: String, amount: int, currency_type: String) -> void:
	if sku != _pending_sku:
		return
	var global_ui: GlobalUI = get_tree().root.get_node("Main/GlobalUi")
	currency_ui.update_currency(true)
	global_ui.show_reward_notification("Currency Top-Up", amount, currency_type)
	_finish()


func _on_purchase_failed(sku: String, error: String) -> void:
	if sku != _pending_sku:
		return
	var global_ui: GlobalUI = get_tree().root.get_node("Main/GlobalUi")
	global_ui.show_error_notification("Purchase failed: %s" % error)
	_finish()


func _on_purchase_cancelled(sku: String) -> void:
	if sku != _pending_sku:
		return
	_finish()


func _finish() -> void:
	_pending_sku = ""
	_set_buttons_disabled(false)


func _set_buttons_disabled(disabled: bool) -> void:
	for child in _grid.get_children():
		if child is BaseButton:
			child.disabled = disabled
