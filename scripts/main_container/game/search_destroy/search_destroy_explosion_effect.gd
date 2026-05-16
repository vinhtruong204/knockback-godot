class_name SearchDestroyExplosionEffect extends Node2D

const EXPLOSION_TEXTURE: Texture2D = preload("res://assets/game/effects/explosion_frag_grenade.png")
const FRAME_COUNT: int = 8
const FRAME_SIZE: Vector2 = Vector2(272.0, 724.0)
const ANIMATION_NAME: StringName = &"explode"

var _flash_radius: float = 0.0
var _flash_alpha: float = 0.0


func _ready() -> void:
	z_as_relative = false
	z_index = 1200
	_play_sprite_animation()
	_play_flash()


func _draw() -> void:
	if _flash_alpha <= 0.0:
		return
	draw_circle(Vector2.ZERO, _flash_radius, Color(1.0, 0.82, 0.22, _flash_alpha * 0.32))
	draw_arc(Vector2.ZERO, _flash_radius, 0.0, TAU, 96, Color(1.0, 0.94, 0.45, _flash_alpha), 7.0)


func _play_sprite_animation() -> void:
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.sprite_frames = _build_sprite_frames()
	sprite.animation = ANIMATION_NAME
	sprite.scale = Vector2(0.74, 0.74)
	sprite.position = Vector2(0.0, -118.0)
	sprite.z_index = 1
	sprite.animation_finished.connect(queue_free)
	add_child(sprite)
	sprite.play(ANIMATION_NAME)


func _build_sprite_frames() -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.add_animation(ANIMATION_NAME)
	frames.set_animation_loop(ANIMATION_NAME, false)
	frames.set_animation_speed(ANIMATION_NAME, 24.0)
	for i in range(FRAME_COUNT):
		var atlas: AtlasTexture = AtlasTexture.new()
		atlas.atlas = EXPLOSION_TEXTURE
		atlas.region = Rect2(Vector2(FRAME_SIZE.x * i, 0.0), FRAME_SIZE)
		frames.add_frame(ANIMATION_NAME, atlas)
	return frames


func _play_flash() -> void:
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "_flash_radius", 190.0, 0.22).from(16.0)
	tween.tween_property(self, "_flash_alpha", 0.0, 0.32).from(1.0)


func _process(_delta: float) -> void:
	queue_redraw()
