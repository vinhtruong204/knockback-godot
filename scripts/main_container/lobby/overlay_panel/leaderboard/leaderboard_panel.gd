class_name LeaderboardPanel extends Panel

enum Mode {
	RAKING,
	NORMAL,
	COLLECTOR
}

const title_item: Dictionary[Mode, String] = {
	Mode.RAKING: "#\tPlayer Name\tWin rate\tKDA\tRank\t",
	Mode.NORMAL: "#\tPlayer Name\tWin rate\tKDA\tTotal Games\t",
	Mode.COLLECTOR: "#\tPlayer Name\tWeapons\tItems\tCharacters\tTotal"
}


@onready var vbox_containter: VBoxContainer = $Panel/Control/StatsPanel/VBoxContainer

var current_mode: Mode = Mode.RAKING


func _ready() -> void:
	_update_leaderboard()

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
	# Print all children of vbox_containter
	var vbox_children = vbox_containter.get_children()

	#region Update title item
	var item0 = vbox_children[0] as Control # title item
	
	# Split title item by tab
	var title_item_split = title_item[current_mode].split("\t")
	
	# Get all labels in title item
	var title_item_labels = item0.get_node("HBoxContainer").get_children()

	# Update title item
	for i in range(title_item_split.size()):
		title_item_labels[i].text = title_item_split[i]

	#endregion

	#region Update leaderboard items
	# Get all items from index 1 to the end
	for i in range(1, vbox_children.size()):
		var item = vbox_children[i] as Control
		
		# Split item by tab
		var item_split = item.get_node("HBoxContainer").get_children()

		# Update item
		for j in range(title_item_split.size()):
			if j == 0:
				item_split[j].text = str(i)
			else:
				item_split[j].text = title_item_labels[j].text

	#endregion
