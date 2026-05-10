class_name TaskPanel extends Panel
enum TaskStatus {IN_PROGRESS, READY, CLAIMED}


var tasks = {
	"daily": [],
	"weekly": []
}

var progress = {} # { task_id: current_value }
@onready var currency_ui: CurrencyContainer = %UIButtons/TopBar/CurrencyContainer
@onready var daily_task_container: VBoxContainer = $Control/DailyPanel/ScrollContainer/VBoxContainer
@onready var weekly_task_container: VBoxContainer = $Control/WeeklyPanel/ScrollContainer/VBoxContainer
@export var task_item: PackedScene

func _ready():
	load_tasks()
	update_task_ui()

func update_task_ui():
	for task in tasks["daily"]:
		var task_item_instance = task_item.instantiate()
		task_item_instance.get_node("TaskName").text = task["name"]
		task_item_instance.get_node("Progress").text = "%d/%d" % [progress[task["id"]], task["target"]]
		task_item_instance.get_node("RewardBtn").text = "%d" % [task["reward_amount"]]
		task_item_instance.get_node("RewardBtn").icon = load("res://assets/lobby/top_bar/currency/%s.png" % task["currency_type"])
		daily_task_container.add_child(task_item_instance)
	
	for task in tasks["weekly"]:
		var task_item_instance = task_item.instantiate()
		task_item_instance.get_node("TaskName").text = task["name"]
		task_item_instance.get_node("Progress").text = "%d/%d" % [progress[task["id"]], task["target"]]
		task_item_instance.get_node("RewardBtn").text = "%d" % [task["reward_amount"]]
		task_item_instance.get_node("RewardBtn").icon = load("res://assets/lobby/top_bar/currency/%s.png" % task["currency_type"])
		weekly_task_container.add_child(task_item_instance)

func load_tasks():
	var file = FileAccess.open("res://scripts/main_container/lobby/overlay_panel/task/data.json", FileAccess.READ)
	var json = JSON.parse_string(file.get_as_text())

	tasks["daily"] = json["daily"]
	tasks["weekly"] = json["weekly"]

	# init progress
	for category in tasks.keys():
		for task in tasks[category]:
			if not progress.has(task["id"]):
				if task["status"] >= TaskStatus.READY:
					progress[task["id"]] = task["target"]
				else:
					progress[task["id"]] = 0


func add_progress(type: String, value: int = 1):
	for category in tasks.keys():
		for task in tasks[category]:
			if task["type"] == type:
				var id = task["id"]
				progress[id] += value

				if is_completed(task) and task["status"] == TaskStatus.IN_PROGRESS:
					task["status"] = TaskStatus.READY


func is_completed(task: Dictionary) -> bool:
	return progress[task["id"]] >= task["target"]


func _on_task_completed(task: Dictionary):
	var reward_amount = task["reward_amount"]
	var currency_type = task["currency_type"]
	var global_ui: GlobalUI = get_tree().root.get_node("Main/GlobalUi")

	PlayerApi.add_player_currency_amount(ApiManager.player_id, currency_type, {"amount": reward_amount},
		func(response: Dictionary):
			if response.get("ok", false):
				currency_ui.update_currency()
				global_ui.show_reward_notification(task["name"], reward_amount, currency_type)
			else:
				global_ui.show_error_notification(tr("TASK_CLAIM_FAILED"))
	)


func get_task_status(task_id: String) -> int:
	var task = get_task_by_id(task_id)
	if task:
		return task["status"]
	return -1


func claim_reward(task_id: String):
	var task = get_task_by_id(task_id)
	if task and task["status"] == TaskStatus.READY:
		_on_task_completed(task)
		task["status"] = TaskStatus.CLAIMED


func get_task_by_id(task_id: String) -> Dictionary:
	for category in tasks.keys():
		for task in tasks[category]:
			if task["id"] == task_id:
				return task
	return {}


func _on_daily_button_pressed():
	show_daily_tasks()


func _on_weekly_button_pressed():
	show_weekly_tasks()


func show_daily_tasks():
	$Control/DailyPanel.show()
	$Control/WeeklyPanel.hide()


func show_weekly_tasks():
	$Control/DailyPanel.hide()
	$Control/WeeklyPanel.show()
