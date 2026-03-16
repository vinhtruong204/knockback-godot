class_name TeamHandlePosition extends Control

@onready var team_hbox := $HBoxContainer

var _origin_pos: Vector2

func _ready() -> void:
	_origin_pos = team_hbox.position

func reset_position():
	team_hbox.position = _origin_pos
	team_hbox.z_index = 0

func change_position_playmode():
	team_hbox.position.x = _origin_pos.x + 400
	team_hbox.z_index = 1

func change_position_equipment():
	team_hbox.position.x = _origin_pos.x + 400
	team_hbox.z_index = 1
