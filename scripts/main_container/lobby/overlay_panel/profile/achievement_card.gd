class_name AchievementCard extends PanelContainer

@onready var icon: TextureRect = $Margin/HBox/Icon
@onready var name_label: Label = $Margin/HBox/TextColumn/Name
@onready var requirement_label: Label = $Margin/HBox/TextColumn/Requirement
@onready var status_label: Label = $Margin/HBox/TextColumn/StatusLabel
@onready var reward_btn: Button = $Margin/HBox/RewardBtn

const ICON_DIR := "res://assets/lobby/top_bar/player_profile/achievement/"
const DEFAULT_ICON_PATH := ICON_DIR + "locked.png"
const FALLBACK_ICON_PATHS := [
	ICON_DIR + "first_win.png",
	ICON_DIR + "win_streak.png",
	ICON_DIR + "sharpshooter.png",
	ICON_DIR + "survivor.png",
	ICON_DIR + "knockback_master.png",
	ICON_DIR + "grenade_expert.png",
	ICON_DIR + "weapon_collector.png",
	ICON_DIR + "rank_climber.png",
	ICON_DIR + "veteran.png",
]

# `progress` may be null when the player has no record for this achievement.
func set_data(achievement: Dictionary, progress) -> void:
	name_label.text = str(achievement.get("name", ""))
	requirement_label.text = str(achievement.get("requirement", ""))

	reward_btn.disabled = true
	reward_btn.text = "--"

	var unlock_at: String = ""
	var current_progress := 0
	if progress != null:
		unlock_at = str(progress.get("unlock_at", "")) if progress.get("unlock_at", null) != null else ""
		current_progress = int(progress.get("progress", 0))

	var is_unlocked := unlock_at != ""
	_set_icon(achievement, is_unlocked)

	if is_unlocked:
		status_label.text = "Unlocked %s" % _format_unlock_date(unlock_at)
		status_label.modulate = Color(0.4, 1.0, 0.5)
	else:
		status_label.text = "Progress: %d" % current_progress
		status_label.modulate = Color(0.8, 0.8, 0.8)


func _set_icon(achievement: Dictionary, is_unlocked: bool) -> void:
	icon.texture = _resolve_icon_texture(achievement)
	icon.modulate = Color.WHITE if is_unlocked else Color(0.45, 0.45, 0.45, 0.78)


func _resolve_icon_texture(achievement: Dictionary) -> Texture2D:
	var configured_texture := _load_icon_texture(str(achievement.get("image", "")))
	if configured_texture != null:
		return configured_texture

	var keyword_path := _get_keyword_icon_path(achievement)
	if keyword_path != "":
		var keyword_texture := load(keyword_path) as Texture2D
		if keyword_texture != null:
			return keyword_texture

	var achievement_id := int(achievement.get("achievement_id", -1))
	if achievement_id >= 0 and not FALLBACK_ICON_PATHS.is_empty():
		var fallback_texture := load(FALLBACK_ICON_PATHS[achievement_id % FALLBACK_ICON_PATHS.size()]) as Texture2D
		if fallback_texture != null:
			return fallback_texture

	return load(DEFAULT_ICON_PATH) as Texture2D


func _load_icon_texture(image_path: String) -> Texture2D:
	image_path = image_path.strip_edges()
	if image_path == "":
		return null

	var candidates: Array[String] = []
	if image_path.begins_with("res://"):
		candidates.append(image_path)
	elif image_path.begins_with("assets/"):
		candidates.append("res://" + image_path)
	elif image_path.contains("/"):
		candidates.append("res://assets/" + image_path)
		candidates.append(ICON_DIR + image_path.get_file())
	else:
		candidates.append(ICON_DIR + image_path)

	for candidate in candidates:
		if ResourceLoader.exists(candidate):
			var resource := load(candidate)
			if resource is Texture2D:
				return resource

	return null


func _get_keyword_icon_path(achievement: Dictionary) -> String:
	var text := "%s %s" % [
		str(achievement.get("name", "")),
		str(achievement.get("requirement", "")),
	]
	text = text.to_lower()

	if text.contains("streak"):
		return ICON_DIR + "win_streak.png"
	if text.contains("sharp") or text.contains("headshot") or text.contains("accuracy"):
		return ICON_DIR + "sharpshooter.png"
	if text.contains("surviv") or text.contains("death") or text.contains("hp"):
		return ICON_DIR + "survivor.png"
	if text.contains("knock") or text.contains("push"):
		return ICON_DIR + "knockback_master.png"
	if text.contains("grenade") or text.contains("bomb"):
		return ICON_DIR + "grenade_expert.png"
	if text.contains("weapon") or text.contains("collect"):
		return ICON_DIR + "weapon_collector.png"
	if text.contains("rank") or text.contains("point"):
		return ICON_DIR + "rank_climber.png"
	if text.contains("game") or text.contains("match") or text.contains("play"):
		return ICON_DIR + "veteran.png"
	if text.contains("win") or text.contains("victory"):
		return ICON_DIR + "first_win.png"

	return ""


# Backend returns ISO 8601 ("2026-04-15T10:30:00Z"). Strip to YYYY-MM-DD.
func _format_unlock_date(iso: String) -> String:
	if iso.length() >= 10:
		return iso.substr(0, 10)
	return iso
