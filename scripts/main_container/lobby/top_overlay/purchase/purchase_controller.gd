class_name PurchaseController extends Panel

@onready var currency_ui: CurrencyContainer = %UIButtons/TopBar/CurrencyContainer

func on_purchase_button_pressed(amount: int, currency_type: String) -> void:
	PlayerApi.add_player_currency_amount(ApiManager.player_id, currency_type, {"amount": amount},
		func(response: Dictionary) -> void:
		if response.get("ok", false):
			print("Success purchase %d %s" % [amount, currency_type])
			
			# Update currency UI
			currency_ui.update_currency()
		else:
			print("Failed to purchase %d %s" % [amount, currency_type])
	)
