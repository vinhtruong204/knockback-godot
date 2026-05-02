class_name WheelItem extends Control

@onready var highlight_border: Panel = $HighlightBorder
@onready var item_texture: TextureRect = $TextureRect
@onready var name_label: Label = $NameLabel
@onready var owned_overlay: ColorRect = $OwnedOverlay

var item_data: Dictionary = {}


func setup(data: Dictionary, owned: bool) -> void:
	item_data = data
	name_label.text = data.get("display_name", "")

	var image_name: String = data.get("image", "")
	var item_type: String = str(data.get("item_type", ""))

	if item_type == "weapon" and image_name != "":
		var path := "res://assets/game/weapon/static/%s" % image_name
		if ResourceLoader.exists(path):
			item_texture.texture = load(path)
	elif item_type == "character" and image_name != "":
		var path := "res://assets/game/player/%s" % image_name
		if ResourceLoader.exists(path):
			item_texture.texture = load(path)
	elif data.get("currency_reward") != null:
		var wheel_type: String = str(data.get("wheel_type", "gold"))
		var path := "res://assets/lobby/top_bar/currency/%s.png" % wheel_type
		if ResourceLoader.exists(path):
			item_texture.texture = load(path)

	owned_overlay.visible = owned
	highlight_border.visible = false


func set_highlighted(active: bool) -> void:
	highlight_border.visible = active
