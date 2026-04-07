class_name PurchaseController extends Panel

@onready var currency_ui: CurrencyContainer = %UIButtons/TopBar/CurrencyContainer

func on_purchase_button_pressed(amount: int, currency_type: String) -> void:
	var global_ui: GlobalUI = get_tree().root.get_node("Main/GlobalUi")
	PlayerApi.add_player_currency_amount(ApiManager.player_id, currency_type, {"amount": amount},
		func(response: Dictionary) -> void:
		if response.get("ok", false):
			currency_ui.update_currency()
			global_ui.show_reward_notification("Currency Top-Up", amount, currency_type)
		else:
			global_ui.show_error_notification("Failed to purchase %d %s" % [amount, currency_type])
	)
