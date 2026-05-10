extends Node

# Android billing backend stub. Wire up to a community Godot 4 Google Play
# Billing Library AAR (e.g. a "GodotGooglePlayBilling" Engine singleton)
# once the AAR is dropped into addons/. Until then, this backend reports
# failure so a misconfigured device cannot silently succeed.
#
# Expected real flow once the plugin is in place:
#   1. plugin.query_sku_details([sku]) -> sku_details_query_completed
#   2. plugin.purchase(sku)            -> purchases_updated (with token)
#   3. PlayerApi.verify_google_purchase(token, sku, cb)
#   4. on cb success: plugin.acknowledge(token) + plugin.consume(token)
#   5. emit purchase_succeeded(sku)
#
# On user cancel (purchases_updated reason = USER_CANCELED) -> emit
# purchase_cancelled. On any other billing error -> emit purchase_failed.

signal purchase_succeeded(sku: String)
signal purchase_failed(sku: String, error: String)
signal purchase_cancelled(sku: String)


func purchase(sku: String) -> void:
	push_warning("Android billing backend is not implemented yet (sku=%s)" % sku)
	purchase_failed.emit(sku, "android_billing_not_implemented")
