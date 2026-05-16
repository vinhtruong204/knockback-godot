class_name OwnerPlayerIndicator extends Node2D

var border_points: PackedVector2Array = PackedVector2Array([
	Vector2(-11.0, -17.0),
	Vector2(11.0, -17.0),
	Vector2(0.0, 1.0),
])
var fill_points: PackedVector2Array = PackedVector2Array([
	Vector2(-8.0, -14.0),
	Vector2(8.0, -14.0),
	Vector2(0.0, -1.0),
])


func _ready() -> void:
	z_index = 120


func _draw() -> void:
	draw_colored_polygon(border_points, Color.BLACK)
	draw_colored_polygon(fill_points, Color(1.0, 0.72, 0.05))
