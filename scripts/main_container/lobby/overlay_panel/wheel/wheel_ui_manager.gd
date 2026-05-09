class_name WheelUIManager extends Panel

const SPIN_RESULTS_POPUP = preload("res://scenes/main_container/lobby/wheel/spin_results_popup.tscn")

var _gold_items: Array = []
var _diamond_items: Array = []
var _gold_wheel_data: Array = []
var _diamond_wheel_data: Array = []
var _owned_item_keys: Dictionary = {}
var _is_spinning: bool = false
var _current_highlight_index: int = -1
var _active_tween: Tween = null
var _skip_btn: Button = null
var _pending_on_complete: Callable
var _pending_winning_index: int = -1
var _pending_items: Array = []


func _ready() -> void:
	_collect_wheel_item_refs()
	_connect_spin_buttons()
	_create_skip_button()
	visibility_changed.connect(_on_visibility_changed)
	if visible:
		_load_wheel_data()


func _create_skip_button() -> void:
	_skip_btn = Button.new()
	_skip_btn.text = "Skip"
	_skip_btn.custom_minimum_size = Vector2(80, 30)
	_skip_btn.visible = false
	_skip_btn.pressed.connect(_on_skip_pressed)
	# Place it below the wheel container, centered
	_skip_btn.anchors_preset = Control.PRESET_CENTER_BOTTOM
	_skip_btn.position = Vector2(-40, -45)
	$Control/WheelContainer.add_child(_skip_btn)


func _on_visibility_changed() -> void:
	if visible:
		_load_wheel_data()


#region Wheel item collection (border order: top→right→bottom→left)
func _collect_wheel_item_refs() -> void:
	var gold_wheel = $Control/WheelContainer/GoldWheel
	var diamond_wheel = $Control/WheelContainer/DiamondWheel
	_gold_items = _get_ordered_items(gold_wheel)
	_diamond_items = _get_ordered_items(diamond_wheel)


func _get_ordered_items(wheel_node: Control) -> Array:
	var items: Array = []
	# Top row: left to right (indices 0-3)
	for child in wheel_node.get_node("HBoxContainer").get_children():
		items.append(child)
	# Right column: top to bottom (indices 4-7)
	for child in wheel_node.get_node("VBoxContainer2").get_children():
		items.append(child)
	# Bottom row: right to left (indices 8-11)
	var bottom := wheel_node.get_node("HBoxContainer2").get_children().duplicate()
	bottom.reverse()
	for child in bottom:
		items.append(child)
	# Left column: bottom to top (indices 12-15)
	var left := wheel_node.get_node("VBoxContainer").get_children().duplicate()
	left.reverse()
	for child in left:
		items.append(child)
	return items
#endregion


#region Tab switching
func _open_gold_wheel() -> void:
	if _is_spinning:
		return
	$Control/WheelContainer/GoldWheel.show()
	$Control/WheelContainer/DiamondWheel.hide()


func _open_diamond_wheel() -> void:
	if _is_spinning:
		return
	$Control/WheelContainer/DiamondWheel.show()
	$Control/WheelContainer/GoldWheel.hide()


func _set_tab_buttons_disabled(disabled: bool) -> void:
	$Control/HBoxContainer/GoldBtn.disabled = disabled
	$Control/HBoxContainer/DiamondBtn.disabled = disabled
#endregion


#region Button connections
func _connect_spin_buttons() -> void:
	var gold_options = $Control/WheelContainer/GoldWheel/GoldOptions
	var diamond_options = $Control/WheelContainer/DiamondWheel/DiamondOptions

	gold_options.get_node("Button").pressed.connect(_on_spin_pressed.bind("gold", 1))
	gold_options.get_node("Button2").pressed.connect(_on_spin_pressed.bind("gold", 10))
	diamond_options.get_node("Button").pressed.connect(_on_spin_pressed.bind("diamond", 1))
	diamond_options.get_node("Button2").pressed.connect(_on_spin_pressed.bind("diamond", 10))
#endregion


#region Data loading
func _load_wheel_data() -> void:
	PlayerApi.get_player_inventory(ApiManager.player_id, func(inv_response: Dictionary) -> void:
		_owned_item_keys.clear()
		if inv_response.get("ok", false):
			var inv_data = inv_response.get("data", [])
			if inv_data is Array:
				for inv in inv_data:
					var key := str(inv.get("item_id", "")) + ":" + str(inv.get("item_type", ""))
					_owned_item_keys[key] = true

		EconomyApi.get_wheel_items("gold", func(response: Dictionary) -> void:
			if response.get("ok", false):
				_gold_wheel_data = response.get("data", [])
				_populate_wheel(_gold_items, _gold_wheel_data)
		)
		EconomyApi.get_wheel_items("diamond", func(response: Dictionary) -> void:
			if response.get("ok", false):
				_diamond_wheel_data = response.get("data", [])
				_populate_wheel(_diamond_items, _diamond_wheel_data)
		)
	, true)


func _populate_wheel(items: Array, data: Array) -> void:
	var sorted_data := data.duplicate()
	sorted_data.sort_custom(func(a, b): return int(a.get("slot_index", 0)) < int(b.get("slot_index", 0)))

	for i in range(mini(items.size(), sorted_data.size())):
		var item_node = items[i]
		var d: Dictionary = sorted_data[i]
		var owned := false
		var item_id = d.get("item_id")
		var item_type = d.get("item_type")
		if item_id != null and item_type != null:
			var key := str(item_id) + ":" + str(item_type)
			owned = _owned_item_keys.has(key)
		item_node.setup(d, owned)
#endregion


#region Spin flow
func _on_spin_pressed(wheel_type: String, spin_count: int) -> void:
	if _is_spinning:
		return

	var cost := 1000 * spin_count
	var global_ui: GlobalUI = get_tree().root.get_node("Main/GlobalUi")
	var label := "Lucky Wheel %dx" % spin_count if spin_count > 1 else "Lucky Wheel"
	global_ui.show_confirm_purchase(label, cost, wheel_type, _do_spin.bind(wheel_type, spin_count))


func _do_spin(wheel_type: String, spin_count: int) -> void:
	_set_buttons_disabled(true)
	_is_spinning = true

	PlayerApi.spin_wheel({"wheel_type": wheel_type, "spin_count": spin_count}, func(response: Dictionary) -> void:
		if not response.get("ok", false):
			var global_ui: GlobalUI = get_tree().root.get_node("Main/GlobalUi")
			global_ui.show_error_notification(response.get("error", "Spin failed"))
			_is_spinning = false
			_set_buttons_disabled(false)
			return

		var data: Dictionary = response.get("data", {})
		var results: Array = data.get("results", [])
		if results.is_empty():
			var global_ui_empty: GlobalUI = get_tree().root.get_node("Main/GlobalUi")
			global_ui_empty.show_error_notification("Spin returned no rewards")
			_is_spinning = false
			_set_buttons_disabled(false)
			return

		var items: Array = _gold_items if wheel_type == "gold" else _diamond_items
		var winning_index: int = int(results[0].get("slot_index", 0))
		_play_spin_animation(items, winning_index, func() -> void:
			if spin_count == 1:
				_show_single_result(results[0], wheel_type)
			else:
				_show_multi_results(results, wheel_type)
			_refresh_after_spin()
		)
	)


func _set_buttons_disabled(disabled: bool) -> void:
	var gold_options = $Control/WheelContainer/GoldWheel/GoldOptions
	var diamond_options = $Control/WheelContainer/DiamondWheel/DiamondOptions
	gold_options.get_node("Button").disabled = disabled
	gold_options.get_node("Button2").disabled = disabled
	diamond_options.get_node("Button").disabled = disabled
	diamond_options.get_node("Button2").disabled = disabled
	_set_tab_buttons_disabled(disabled)
#endregion


#region Animation
func _play_spin_animation(items: Array, winning_index: int, on_complete: Callable) -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()

	var total_items := items.size()
	if total_items == 0:
		on_complete.call()
		return

	# Store state for skip
	_pending_on_complete = on_complete
	_pending_winning_index = winning_index
	_pending_items = items
	_skip_btn.visible = true

	# Calculate total steps: 2 full loops + landing position
	var full_loops := 2
	var extra_steps := randi() % total_items
	var total_steps: int = full_loops * total_items + winning_index + extra_steps
	total_steps = maxi(total_steps, total_items * 2)

	_active_tween = create_tween()
	_current_highlight_index = -1

	for step in range(total_steps):
		var target_idx: int = step % total_items
		var progress: float = float(step) / float(total_steps)
		var delay: float = lerpf(0.05, 0.35, progress * progress)

		_active_tween.tween_callback(_highlight_item.bind(items, target_idx))
		_active_tween.tween_interval(delay)

	_active_tween.tween_callback(_finish_animation)


func _on_skip_pressed() -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	_finish_animation()


func _finish_animation() -> void:
	# Jump highlight to the winning item
	_highlight_item(_pending_items, _pending_winning_index)
	_skip_btn.visible = false
	_is_spinning = false
	_set_buttons_disabled(false)
	if _pending_on_complete.is_valid():
		_pending_on_complete.call()


func _highlight_item(items: Array, index: int) -> void:
	if _current_highlight_index >= 0 and _current_highlight_index < items.size():
		items[_current_highlight_index].set_highlighted(false)
	if index >= 0 and index < items.size():
		items[index].set_highlighted(true)
	_current_highlight_index = index
#endregion


#region Results display
func _show_single_result(result: Dictionary, wheel_type: String) -> void:
	var global_ui: GlobalUI = get_tree().root.get_node("Main/GlobalUi")
	var display_name: String = result.get("display_name", "Unknown")
	var is_duplicate: bool = result.get("is_duplicate", false)
	var compensation: int = int(result.get("compensation_amount", 0))

	if is_duplicate:
		global_ui.show_reward_notification(
			"Duplicate: " + display_name, compensation, wheel_type
		)
	elif result.get("currency_reward") != null:
		global_ui.show_reward_notification(
			display_name, int(result.get("currency_reward", 0)), wheel_type
		)
	else:
		global_ui.show_reward_notification(display_name + " (NEW!)", 0, "")


func _show_multi_results(results: Array, wheel_type: String) -> void:
	var popup = SPIN_RESULTS_POPUP.instantiate()
	add_child(popup)
	popup.show_results(results, wheel_type)


func _refresh_after_spin() -> void:
	var currency_container = get_node_or_null("../../UIButtons/TopBar/CurrencyContainer")
	if currency_container and currency_container.has_method("update_currency"):
		currency_container.update_currency(true)
	_load_wheel_data()
#endregion
