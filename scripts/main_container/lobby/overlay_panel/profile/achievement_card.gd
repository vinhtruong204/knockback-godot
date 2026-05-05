class_name AchievementCard extends PanelContainer

@onready var icon: TextureRect = $Margin/HBox/Icon
@onready var name_label: Label = $Margin/HBox/TextColumn/Name
@onready var requirement_label: Label = $Margin/HBox/TextColumn/Requirement
@onready var status_label: Label = $Margin/HBox/TextColumn/StatusLabel
@onready var reward_btn: Button = $Margin/HBox/RewardBtn

# `progress` may be null when the player has no record for this achievement.
func set_data(achievement: Dictionary, progress) -> void:
	name_label.text = str(achievement.get("name", ""))
	requirement_label.text = str(achievement.get("requirement", ""))

	icon.texture = null

	reward_btn.disabled = true
	reward_btn.text = "--"

	var unlock_at: String = ""
	var current_progress := 0
	if progress != null:
		unlock_at = str(progress.get("unlock_at", "")) if progress.get("unlock_at", null) != null else ""
		current_progress = int(progress.get("progress", 0))

	if unlock_at != "":
		status_label.text = "✓ Unlocked %s" % _format_unlock_date(unlock_at)
		status_label.modulate = Color(0.4, 1.0, 0.5)
	else:
		status_label.text = "Progress: %d" % current_progress
		status_label.modulate = Color(0.8, 0.8, 0.8)


# Backend returns ISO 8601 ("2026-04-15T10:30:00Z"). Strip to YYYY-MM-DD.
func _format_unlock_date(iso: String) -> String:
	if iso.length() >= 10:
		return iso.substr(0, 10)
	return iso
