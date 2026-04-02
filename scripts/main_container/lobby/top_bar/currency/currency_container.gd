class_name CurrencyContainer extends HBoxContainer

@onready var gold_btn: Button = $GoldBtn
@onready var diamond_btn: Button = $DiamondBtn

func _init() -> void:
	update_currency()

func update_currency() -> void:
	PlayerApi.get_player_currency(ApiManager.player_id, Enums.CurrencyType.GOLD, func(response: Dictionary) -> void:
		if response.get("ok", false):
			var currencies = response.get("data")
			gold_btn.text = "%d" % int(currencies.get("amount"))
	)

	PlayerApi.get_player_currency(ApiManager.player_id, Enums.CurrencyType.DIAMOND, func(response: Dictionary) -> void:
		if response.get("ok", false):
			var currencies = response.get("data")
			diamond_btn.text = "%d" % int(currencies.get("amount"))
	)
