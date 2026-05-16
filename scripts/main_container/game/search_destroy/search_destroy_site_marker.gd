class_name SearchDestroySiteMarker extends Node2D

const RADIUS := 84.0
const ZONE_OPACITY := 0.5
const PLANTED_BOMB_SIZE := 92.0
const ZONE_TEXTURE: Texture2D = preload("res://assets/game/search_destroy/plant_area_zone.png")
const PLANTED_TEXTURE: Texture2D = preload("res://assets/game/search_destroy/planted_bomb_device.png")

var site_label: String = "A":
	set(value):
		site_label = value
		_update_label()

var bomb_planted: bool = false:
	set(value):
		bomb_planted = value
		_refresh_visual_state()
		queue_redraw()

var _label: Label
var _zone_sprite: Sprite2D
var _planted_bomb_sprite: Sprite2D

var active: bool = false:
	set(value):
		active = value
		visible = active
		_refresh_visual_state()
		_update_label()
		queue_redraw()


func _ready() -> void:
	z_as_relative = false
	z_index = 1000
	_zone_sprite = Sprite2D.new()
	_zone_sprite.name = "PlantAreaZone"
	_zone_sprite.texture = ZONE_TEXTURE
	_zone_sprite.centered = true
	_zone_sprite.modulate = Color(1.0, 1.0, 1.0, ZONE_OPACITY)
	add_child(_zone_sprite)

	_planted_bomb_sprite = Sprite2D.new()
	_planted_bomb_sprite.name = "PlantedBombDevice"
	_planted_bomb_sprite.texture = PLANTED_TEXTURE
	_planted_bomb_sprite.centered = true
	add_child(_planted_bomb_sprite)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.position = Vector2(-90.0, -126.0)
	_label.size = Vector2(180.0, 34.0)
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color(1.0, 0.91, 0.36))
	_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	_label.add_theme_constant_override("shadow_offset_x", 2)
	_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(_label)
	visible = active
	_fit_sprite_to_diameter(_zone_sprite, RADIUS * 2.0)
	_fit_sprite_to_diameter(_planted_bomb_sprite, PLANTED_BOMB_SIZE)
	_refresh_visual_state()
	_update_label()


func _fit_sprite_to_diameter(sprite: Sprite2D, diameter: float) -> void:
	if sprite == null or sprite.texture == null:
		return
	var texture_size: Vector2 = sprite.texture.get_size()
	var max_edge: float = maxf(texture_size.x, texture_size.y)
	if max_edge <= 0.0:
		return
	var scale_value: float = diameter / max_edge
	sprite.scale = Vector2(scale_value, scale_value)


func _refresh_visual_state() -> void:
	if _zone_sprite:
		_zone_sprite.visible = active
	if _planted_bomb_sprite:
		_planted_bomb_sprite.visible = active and bomb_planted


func _update_label() -> void:
	if _label == null:
		return
	_label.visible = active
	_label.text = "PLANT AREA " + site_label
