class_name CurrencyContainer extends HBoxContainer

@onready var gold_btn: Button = $GoldBtn
@onready var diamond_btn: Button = $DiamondBtn

func _ready() -> void:
	update_currency(true)

func update_currency(force_refresh := false) -> void:
	PlayerApi.get_player_currency(ApiManager.player_id, Enums.CurrencyType.GOLD, func(response: Dictionary) -> void:
		if response.get("ok", false):
			var currencies = response.get("data")
			gold_btn.text = "%d" % int(currencies.get("amount"))
	, force_refresh)

	PlayerApi.get_player_currency(ApiManager.player_id, Enums.CurrencyType.DIAMOND, func(response: Dictionary) -> void:
		if response.get("ok", false):
			var currencies = response.get("data")
			diamond_btn.text = "%d" % int(currencies.get("amount"))
	, force_refresh)
