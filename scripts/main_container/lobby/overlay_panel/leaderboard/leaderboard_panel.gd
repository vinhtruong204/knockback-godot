class_name LeaderboardPanel extends Panel

enum Mode {
	RAKING,
	NORMAL,
	COLLECTOR
}

const title_keys: Dictionary[Mode, Array] = {
	Mode.RAKING: ["#", "LB_COL_PLAYER_NAME", "LB_COL_WIN_RATE", "LB_COL_KDA", "LB_COL_RANK", ""],
	Mode.NORMAL: ["#", "LB_COL_PLAYER_NAME", "LB_COL_WIN_RATE", "LB_COL_KDA", "LB_COL_TOTAL_GAMES", ""],
	Mode.COLLECTOR: ["#", "LB_COL_PLAYER_NAME", "LB_COL_WEAPONS", "LB_COL_ITEMS", "LB_COL_CHARACTER", "LB_COL_TOTAL"]
}

const mode_to_api: Dictionary[Mode, String] = {
	Mode.RAKING: "ranking",
	Mode.NORMAL: "normal",
	Mode.COLLECTOR: "collector"
}

@onready var vbox_containter: VBoxContainer = $Panel/Control/StatsPanel/VBoxContainer

var current_mode: Mode = Mode.RAKING


func _ready() -> void:
	_setup_column_layout()
	_update_leaderboard()

func _setup_column_layout() -> void:
	for row in vbox_containter.get_children():
		for label in row.get_node("HBoxContainer").get_children():
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _on_ranking_button_pressed() -> void:
	current_mode = Mode.RAKING
	_update_leaderboard()

func _on_normal_button_pressed() -> void:
	current_mode = Mode.NORMAL
	_update_leaderboard()

func _on_collector_button_pressed() -> void:
	current_mode = Mode.COLLECTOR
	_update_leaderboard()

func _update_leaderboard() -> void:
	_update_title_row()
	_clear_data_rows()

	var mode_str: String = mode_to_api[current_mode]
	PlayerApi.get_leaderboard(mode_str, func(response: Dictionary):
		if response.get("ok", false):
			var data: Dictionary = response.get("data", {})
			var entries: Array = data.get("entries", [])
			_populate_rows(entries)
	)

func _update_title_row() -> void:
	var vbox_children = vbox_containter.get_children()
	var item0 = vbox_children[0] as Control
	var keys = title_keys[current_mode]
	var title_labels = item0.get_node("HBoxContainer").get_children()
	for i in range(keys.size()):
		var k: String = keys[i]
		title_labels[i].text = "" if k == "" else (k if k == "#" else tr(k))

func _clear_data_rows() -> void:
	var vbox_children = vbox_containter.get_children()
	for i in range(1, vbox_children.size()):
		var row_labels = vbox_children[i].get_node("HBoxContainer").get_children()
		for label in row_labels:
			label.text = "-"

func _populate_rows(entries: Array) -> void:
	var vbox_children = vbox_containter.get_children()
	for i in range(1, vbox_children.size()):
		var row_labels = vbox_children[i].get_node("HBoxContainer").get_children()
		var entry_index = i - 1
		if entry_index < entries.size():
			var entry: Dictionary = entries[entry_index]
			row_labels[0].text = str(int(entry.get("position", i)))
			row_labels[1].text = str(entry.get("player_name", "-"))
			match current_mode:
				Mode.RAKING:
					row_labels[2].text = "%.1f%%" % entry.get("win_rate", 0.0)
					row_labels[3].text = "%.2f" % entry.get("kda", 0.0)
					row_labels[4].text = str(entry.get("rank_name", "-"))
					row_labels[5].text = ""
				Mode.NORMAL:
					row_labels[2].text = "%.1f%%" % entry.get("win_rate", 0.0)
					row_labels[3].text = "%.2f" % entry.get("kda", 0.0)
					row_labels[4].text = str(int(entry.get("total_game", 0)))
					row_labels[5].text = ""
				Mode.COLLECTOR:
					row_labels[2].text = str(int(entry.get("weapon_count", 0)))
					row_labels[3].text = str(int(entry.get("item_count", 0)))
					row_labels[4].text = str(int(entry.get("character_count", 0)))
					row_labels[5].text = str(int(entry.get("total_items", 0)))
		else:
			for label in row_labels:
				label.text = "-"
