extends Node

# Mirror of GOOGLE_PLAY_SKU_CATALOG in player-service/app/services/purchase_service.py.
# Server is source of truth — this table is only used to map a SKU back to a
# currency amount for the local "Currency Top-Up" reward notification.
const SKU_TABLE := {
	"diamond_pack_10000": {"amount": 10000, "currency_type": "diamond"},
	"diamond_pack_5000":  {"amount": 5000,  "currency_type": "diamond"},
	"diamond_pack_1000":  {"amount": 1000,  "currency_type": "diamond"},
	"diamond_pack_500":   {"amount": 500,   "currency_type": "diamond"},
	"gold_pack_10000":    {"amount": 10000, "currency_type": "gold"},
	"gold_pack_5000":     {"amount": 5000,  "currency_type": "gold"},
}

signal purchase_succeeded(sku: String, amount: int, currency_type: String)
signal purchase_failed(sku: String, error: String)
signal purchase_cancelled(sku: String)

const _MockBackend := preload("res://scripts/global_scripts/billing/_mock_billing_backend.gd")
const _AndroidBackend := preload("res://scripts/global_scripts/billing/_android_billing_backend.gd")

var _backend: Node


func _ready() -> void:
	if OS.get_name() == "Android" and Engine.has_singleton("GodotGooglePlayBilling"):
		_backend = _AndroidBackend.new()
	else:
		_backend = _MockBackend.new()
	add_child(_backend)
	_backend.purchase_succeeded.connect(_on_backend_succeeded)
	_backend.purchase_failed.connect(_on_backend_failed)
	_backend.purchase_cancelled.connect(_on_backend_cancelled)


func purchase(sku: String) -> void:
	if not SKU_TABLE.has(sku):
		purchase_failed.emit(sku, "sku_unknown")
		return
	_backend.purchase(sku)


func get_sku_info(sku: String) -> Dictionary:
	return SKU_TABLE.get(sku, {})


func _on_backend_succeeded(sku: String) -> void:
	var info: Dictionary = SKU_TABLE.get(sku, {})
	var amount: int = info.get("amount", 0)
	var currency_type: String = info.get("currency_type", "")
	purchase_succeeded.emit(sku, amount, currency_type)


func _on_backend_failed(sku: String, error: String) -> void:
	purchase_failed.emit(sku, error)


func _on_backend_cancelled(sku: String) -> void:
	purchase_cancelled.emit(sku)
