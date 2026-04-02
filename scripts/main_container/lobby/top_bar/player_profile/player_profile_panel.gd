class_name PlayerProfilePanel extends Panel

@onready var level_label: Label = $ProfilePanel/Level
@onready var name_label: Label = $ProfilePanel/PlayerName/Label
@onready var avatar: TextureRect = $ProfilePanel/Avatar
@onready var slogan_edit: TextEdit = $ProfilePanel/SloganEditor
@onready var stats_text: RichTextLabel = $StatsPanel/ContentContainer/StatsText

func _ready() -> void:
	self.visibility_changed.connect(_on_visibility_changed)
	slogan_edit.connect("focus_exited", _on_slogan_edit_focus_exited)

	# Default to ranking tab
	on_ranking_button_pressed()

func _on_slogan_edit_focus_exited() -> void:
	PlayerApi.update_player(ApiManager.player_id, {"slogan": slogan_edit.text}, func(response: Dictionary) -> void:
		if response.get("ok", false):
			print("Slogan updated successfully")
		else:
			print("Failed to update slogan")
	)

func _on_visibility_changed() -> void:
	if self.visible:
		PlayerApi.get_player(ApiManager.player_id, func(response: Dictionary) -> void:
			if response.get("ok", false):
				var player = response.get("data")
				level_label.text = "LV. %d" % player.get("current_level_id")
				name_label.text = player.get("name")
				slogan_edit.text = player.get("slogan")
		)

func on_ranking_button_pressed() -> void:
	stats_text.text = """Current rank: Diamond

Rank points: 3200

Totals game: 50

Win rate: 50%

KDA: 2.3"""


func on_normal_button_pressed() -> void:
	stats_text.text = """Total games: 50

Win rate: 50%

KDA: 2.3"""


func on_achivement_button_pressed() -> void:
	stats_text.text = """"""
