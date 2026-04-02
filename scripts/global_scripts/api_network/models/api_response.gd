class_name ApiResponse
## Wrapper for all API responses from ApiManager.
## Matches the response format: { ok, status, data, error }

var ok: bool
var status: int
var data: Variant
var error: String


static func from_dict(response: Dictionary) -> ApiResponse:
	var model := ApiResponse.new()
	model.ok = response.get("ok", false)
	model.status = response.get("status", 0)
	model.data = response.get("data")
	model.error = response.get("error", "")
	return model


func get_data_as_dict() -> Dictionary:
	if data is Dictionary:
		return data
	return {}


func get_data_as_array() -> Array:
	if data is Array:
		return data
	return []
