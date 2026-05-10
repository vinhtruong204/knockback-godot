extends Node

# Mock billing backend for editor / non-Android builds.
# Auto-succeeds: generates a fake purchase token and routes through
# PlayerApi.verify_google_purchase so the real backend code path is exercised.

signal purchase_succeeded(sku: String)
signal purchase_failed(sku: String, error: String)
signal purchase_cancelled(sku: String)


func purchase(sku: String) -> void:
	var token := "mock_%s_%d" % [sku, Time.get_unix_time_from_system()]
	PlayerApi.verify_google_purchase(token, sku, func(response: Dictionary) -> void:
		if response.get("ok", false):
			purchase_succeeded.emit(sku)
		else:
			var err: String = response.get("error", "unknown_error")
			purchase_failed.emit(sku, err)
	)
