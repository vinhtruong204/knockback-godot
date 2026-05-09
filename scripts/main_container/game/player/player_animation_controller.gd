class_name PlayerAnimationController extends Node

const ANIM_IDLE := "idle"
const ANIM_RUN := "run"
const ANIM_JUMP := "jump"
const ANIM_FALL := "fall"
const ANIM_SHOOT := "shoot"
const ANIM_RELOAD := "reload"
const ANIM_MELEE := "melee"

const SHOOT_DURATION := 0.16
const MELEE_DURATION := 0.22

@export var current_animation: String = ANIM_IDLE:
	set(value):
		if current_animation == value:
			return
		current_animation = value
		_play_animation(value)

@onready var animation_player: AnimationPlayer = $"../ChracterSprites/CharacterAnimationPlayer"
@onready var movement_state_machine: MovementStateMachine = $"../MovementStateMachine"
@onready var player_attack: PlayerAttack = $"../PlayerActtack" as PlayerAttack
@onready var weapon_hold_handler: WeaponHoldHandler = $"../ChracterSprites/WeaponHoldHandler"

var _movement_animation: String = ANIM_IDLE
var _action_locked := false
var _action_token := 0


func _ready() -> void:
	_build_animation_library()
	_play_animation(current_animation)

	if not is_multiplayer_authority():
		return

	movement_state_machine.state_changed.connect(_on_movement_state_changed)
	if player_attack != null:
		player_attack.shot_fired.connect(_on_shot_fired)
		player_attack.melee_attack_fired.connect(_on_melee_attack_fired)
	weapon_hold_handler.reload_started.connect(_on_reload_started)
	weapon_hold_handler.reload_finished.connect(_on_reload_finished)


func _on_movement_state_changed(new_state_name: Variant) -> void:
	_movement_animation = _animation_for_movement_state(StringName(new_state_name))
	if not _action_locked:
		_set_visual_animation(_movement_animation)


func _on_shot_fired() -> void:
	if current_animation == ANIM_RELOAD:
		_play_shoot_before_reload()
		return
	_play_action_animation(ANIM_SHOOT, SHOOT_DURATION)


func _on_melee_attack_fired() -> void:
	_play_action_animation(ANIM_MELEE, MELEE_DURATION)


func _on_reload_started(slot: String) -> void:
	if slot == Enums.SlotType.MELEE:
		return
	if current_animation == ANIM_SHOOT:
		_play_reload_after_shoot()
		return
	_play_action_animation(ANIM_RELOAD, WeaponHoldHandler.RELOAD_DELAY)


func _on_reload_finished(_slot: String) -> void:
	if current_animation != ANIM_RELOAD:
		return
	_action_token += 1
	_action_locked = false
	_set_visual_animation(_movement_animation)


func _play_action_animation(animation_name: String, duration: float) -> void:
	_action_token += 1
	var token := _action_token
	_action_locked = true
	_set_visual_animation(animation_name, true)

	await get_tree().create_timer(duration).timeout
	if token != _action_token or not is_inside_tree():
		return
	_action_locked = false
	_set_visual_animation(_movement_animation)


func _play_shoot_before_reload() -> void:
	_action_token += 1
	var token := _action_token
	_action_locked = true
	_set_visual_animation(ANIM_SHOOT, true)

	await get_tree().create_timer(SHOOT_DURATION).timeout
	if token != _action_token or not is_inside_tree():
		return
	_play_action_animation(ANIM_RELOAD, max(WeaponHoldHandler.RELOAD_DELAY - SHOOT_DURATION, 0.1))


func _play_reload_after_shoot() -> void:
	var token := _action_token
	await get_tree().create_timer(SHOOT_DURATION).timeout
	if token != _action_token or not is_inside_tree() or current_animation != ANIM_SHOOT:
		return
	_play_action_animation(ANIM_RELOAD, max(WeaponHoldHandler.RELOAD_DELAY - SHOOT_DURATION, 0.1))


func _set_visual_animation(animation_name: String, force_replay := false) -> void:
	if current_animation == animation_name and force_replay:
		_play_animation(animation_name)
		return
	current_animation = animation_name


func _play_animation(animation_name: String) -> void:
	if animation_player == null or not animation_player.has_animation(animation_name):
		return
	if animation_player.current_animation == animation_name:
		animation_player.stop()
	animation_player.play(animation_name)


func _animation_for_movement_state(state_name: StringName) -> String:
	match state_name:
		MovementState.RUN:
			return ANIM_RUN
		MovementState.JUMP:
			return ANIM_JUMP
		MovementState.FALL:
			return ANIM_FALL
	return ANIM_IDLE


func _build_animation_library() -> void:
	var library := AnimationLibrary.new()
	library.add_animation(ANIM_IDLE, _build_idle_animation())
	library.add_animation(ANIM_RUN, _build_run_animation())
	library.add_animation(ANIM_JUMP, _build_jump_animation())
	library.add_animation(ANIM_FALL, _build_fall_animation())
	library.add_animation(ANIM_SHOOT, _build_shoot_animation())
	library.add_animation(ANIM_RELOAD, _build_reload_animation())
	library.add_animation(ANIM_MELEE, _build_melee_animation())

	if animation_player.has_animation_library(""):
		animation_player.remove_animation_library("")
	animation_player.add_animation_library("", library)


func _new_animation(length: float, loop_mode := Animation.LOOP_NONE) -> Animation:
	var animation := Animation.new()
	animation.length = length
	animation.loop_mode = loop_mode
	return animation


func _add_value_track(animation: Animation, path: NodePath, times: Array, values: Array) -> void:
	var track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, path)
	for i in range(times.size()):
		animation.track_insert_key(track, float(times[i]), values[i])


func _add_base_tracks(animation: Animation, times: Array, overrides := {}) -> void:
	_add_value_track(animation, ^"CharacterBody:position", times, _track_values("CharacterBody:position", Vector2.ZERO, times.size(), overrides))
	_add_value_track(animation, ^"CharacterBody:rotation", times, _track_values("CharacterBody:rotation", 0.0, times.size(), overrides))
	_add_value_track(animation, ^"LeftLeg:position", times, _track_values("LeftLeg:position", Vector2(-9, 49), times.size(), overrides))
	_add_value_track(animation, ^"LeftLeg:rotation", times, _track_values("LeftLeg:rotation", 0.0, times.size(), overrides))
	_add_value_track(animation, ^"RightLeg:position", times, _track_values("RightLeg:position", Vector2(9, 49), times.size(), overrides))
	_add_value_track(animation, ^"RightLeg:rotation", times, _track_values("RightLeg:rotation", 0.0, times.size(), overrides))
	_add_value_track(animation, ^"WeaponHoldHandler:position", times, _track_values("WeaponHoldHandler:position", Vector2.ZERO, times.size(), overrides))
	_add_value_track(animation, ^"WeaponHoldHandler:rotation", times, _track_values("WeaponHoldHandler:rotation", 0.0, times.size(), overrides))
	_add_value_track(animation, ^"WeaponHoldHandler/Melee:position", times, _track_values("WeaponHoldHandler/Melee:position", Vector2(-29, 21), times.size(), overrides))
	_add_value_track(animation, ^"WeaponHoldHandler/Melee:rotation", times, _track_values("WeaponHoldHandler/Melee:rotation", 0.0, times.size(), overrides))
	_add_value_track(animation, ^"WeaponHoldHandler/KnifeSlash:visible", times, _track_values("WeaponHoldHandler/KnifeSlash:visible", false, times.size(), overrides))
	_add_value_track(animation, ^"WeaponHoldHandler/KnifeSlash:position", times, _track_values("WeaponHoldHandler/KnifeSlash:position", Vector2(-47, 16), times.size(), overrides))
	_add_value_track(animation, ^"WeaponHoldHandler/KnifeSlash:rotation", times, _track_values("WeaponHoldHandler/KnifeSlash:rotation", 0.0, times.size(), overrides))
	_add_value_track(animation, ^"WeaponHoldHandler/KnifeSlash:scale", times, _track_values("WeaponHoldHandler/KnifeSlash:scale", Vector2(0.45, 0.45), times.size(), overrides))
	_add_value_track(animation, ^"WeaponHoldHandler/Left_Hand:position", times, _track_values("WeaponHoldHandler/Left_Hand:position", Vector2(-11, 15), times.size(), overrides))
	_add_value_track(animation, ^"WeaponHoldHandler/Left_Hand:rotation", times, _track_values("WeaponHoldHandler/Left_Hand:rotation", 0.0, times.size(), overrides))
	_add_value_track(animation, ^"WeaponHoldHandler/Right_Hand:position", times, _track_values("WeaponHoldHandler/Right_Hand:position", Vector2(-39, 16), times.size(), overrides))
	_add_value_track(animation, ^"WeaponHoldHandler/Right_Hand:rotation", times, _track_values("WeaponHoldHandler/Right_Hand:rotation", 0.0, times.size(), overrides))


func _build_idle_animation() -> Animation:
	var animation := _new_animation(0.8, Animation.LOOP_LINEAR)
	var times := [0.0, 0.4, 0.8]
	_add_base_tracks(animation, times, {
		"CharacterBody:position": [Vector2.ZERO, Vector2(0, -1), Vector2.ZERO],
		"WeaponHoldHandler:position": [Vector2.ZERO, Vector2(0, -1), Vector2.ZERO],
	})
	return animation


func _build_run_animation() -> Animation:
	var animation := _new_animation(0.48, Animation.LOOP_LINEAR)
	var times := [0.0, 0.12, 0.24, 0.36, 0.48]
	_add_base_tracks(animation, times, {
		"CharacterBody:position": [Vector2.ZERO, Vector2(0, -2), Vector2.ZERO, Vector2(0, -2), Vector2.ZERO],
		"LeftLeg:position": [Vector2(-9, 49), Vector2(-13, 47), Vector2(-9, 49), Vector2(-5, 51), Vector2(-9, 49)],
		"LeftLeg:rotation": [0.0, -0.28, 0.0, 0.22, 0.0],
		"RightLeg:position": [Vector2(9, 49), Vector2(5, 51), Vector2(9, 49), Vector2(13, 47), Vector2(9, 49)],
		"RightLeg:rotation": [0.0, 0.22, 0.0, -0.28, 0.0],
		"WeaponHoldHandler:position": [Vector2.ZERO, Vector2(-2, -2), Vector2.ZERO, Vector2(2, -1), Vector2.ZERO],
	})
	return animation


func _build_jump_animation() -> Animation:
	var animation := _new_animation(0.24)
	var times := [0.0, 0.12, 0.24]
	_add_base_tracks(animation, times, {
		"CharacterBody:position": [Vector2.ZERO, Vector2(0, -4), Vector2(0, -3)],
		"LeftLeg:position": [Vector2(-9, 49), Vector2(-12, 42), Vector2(-11, 43)],
		"RightLeg:position": [Vector2(9, 49), Vector2(12, 42), Vector2(11, 43)],
		"WeaponHoldHandler:position": [Vector2.ZERO, Vector2(-1, -4), Vector2(-1, -3)],
	})
	return animation


func _build_fall_animation() -> Animation:
	var animation := _new_animation(0.5, Animation.LOOP_LINEAR)
	var times := [0.0, 0.25, 0.5]
	_add_base_tracks(animation, times, {
		"CharacterBody:position": [Vector2(0, -2), Vector2.ZERO, Vector2(0, -2)],
		"LeftLeg:position": [Vector2(-8, 51), Vector2(-9, 53), Vector2(-8, 51)],
		"RightLeg:position": [Vector2(8, 51), Vector2(9, 53), Vector2(8, 51)],
		"WeaponHoldHandler:position": [Vector2(-1, -2), Vector2.ZERO, Vector2(-1, -2)],
	})
	return animation


func _build_shoot_animation() -> Animation:
	var animation := _new_animation(SHOOT_DURATION)
	var times := [0.0, 0.06, SHOOT_DURATION]
	_add_base_tracks(animation, times, {
		"WeaponHoldHandler:position": [Vector2.ZERO, Vector2(-5, -1), Vector2.ZERO],
		"WeaponHoldHandler:rotation": [0.0, -0.08, 0.0],
		"WeaponHoldHandler/Left_Hand:position": [Vector2(-11, 15), Vector2(-16, 14), Vector2(-11, 15)],
		"WeaponHoldHandler/Right_Hand:position": [Vector2(-39, 16), Vector2(-43, 15), Vector2(-39, 16)],
	})
	return animation


func _build_reload_animation() -> Animation:
	var animation := _new_animation(WeaponHoldHandler.RELOAD_DELAY)
	var times := [0.0, 0.35, 0.8, 1.15, WeaponHoldHandler.RELOAD_DELAY]
	_add_base_tracks(animation, times, {
		"WeaponHoldHandler:position": [Vector2.ZERO, Vector2(-2, 5), Vector2(3, 7), Vector2(-2, 3), Vector2.ZERO],
		"WeaponHoldHandler:rotation": [0.0, 0.28, -0.2, 0.12, 0.0],
		"WeaponHoldHandler/Left_Hand:position": [Vector2(-11, 15), Vector2(-14, 22), Vector2(-8, 24), Vector2(-13, 17), Vector2(-11, 15)],
		"WeaponHoldHandler/Right_Hand:position": [Vector2(-39, 16), Vector2(-35, 24), Vector2(-42, 23), Vector2(-37, 18), Vector2(-39, 16)],
	})
	return animation


func _build_melee_animation() -> Animation:
	var animation := _new_animation(MELEE_DURATION)
	var times := [0.0, 0.07, 0.14, MELEE_DURATION]
	_add_base_tracks(animation, times, {
		"WeaponHoldHandler:position": [Vector2.ZERO, Vector2(-2, -1), Vector2(-5, 0), Vector2.ZERO],
		"WeaponHoldHandler/Melee:position": [Vector2(-29, 21), Vector2(-46, 13), Vector2(-56, 10), Vector2(-29, 21)],
		"WeaponHoldHandler/Melee:rotation": [0.0, -0.55, -0.95, 0.0],
		"WeaponHoldHandler/KnifeSlash:visible": [false, true, true, false],
		"WeaponHoldHandler/KnifeSlash:position": [Vector2(-47, 16), Vector2(-67, 6), Vector2(-70, 6), Vector2(-47, 16)],
		"WeaponHoldHandler/KnifeSlash:rotation": [0.0, -0.18, -0.18, 0.0],
		"WeaponHoldHandler/KnifeSlash:scale": [Vector2(0.35, 0.35), Vector2(0.55, 0.55), Vector2(0.6, 0.6), Vector2(0.35, 0.35)],
		"WeaponHoldHandler/Left_Hand:position": [Vector2(-11, 15), Vector2(-22, 12), Vector2(-28, 10), Vector2(-11, 15)],
		"WeaponHoldHandler/Right_Hand:position": [Vector2(-39, 16), Vector2(-48, 13), Vector2(-54, 12), Vector2(-39, 16)],
	})
	return animation


func _track_values(path: String, default_value: Variant, count: int, overrides: Dictionary) -> Array:
	if overrides.has(path):
		return overrides[path]
	return _repeat(default_value, count)


func _repeat(value: Variant, count: int) -> Array:
	var values: Array = []
	for _i in range(count):
		values.append(value)
	return values
