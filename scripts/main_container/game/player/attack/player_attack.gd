class_name PlayerAttack extends Node

signal shot_fired()
signal melee_attack_fired()

const MELEE_RANGE: float = 45.0
const MELEE_HEIGHT: float = 35.0
const MELEE_KNOCKBACK_FORCE: float = 90.0

@onready var player: CharacterBody2D = $"../"
@onready var gun_barrel: Node2D = $GunBarrel
@onready var player_input: PlayerInput = $"../PlayerInput"
@onready var player_flip: PlayerFlip = $"../PlayerFlip"
@onready var weapon_hold_handler: WeaponHoldHandler = $"../ChracterSprites/WeaponHoldHandler"
@onready var bullet_spawner: BulletSpawner

var _next_shot_time_ms: int = 0

func _ready() -> void:
	# Separate get node for bullet spawner (Because bullet spawner is in different scene)
	# IMPORTANT: Bullet only spawn in server, only need reference to bullet spawner in server
	if multiplayer.is_server():
		bullet_spawner = get_tree().root.get_node("Main/SceneContainer/Game/World/BulletSpawner")

	if is_multiplayer_authority():
		player_input.shoot.connect(_on_shoot)


func _on_shoot() -> void:
	var stats := weapon_hold_handler.get_active_stats()
	var active_slot := weapon_hold_handler.get_active_slot()
	var fire_rate := float(stats.get("fire_rate", WeaponHoldHandler.DEFAULT_FIRE_RATE))
	var now_ms := Time.get_ticks_msec()
	if fire_rate > 0.0 and now_ms < _next_shot_time_ms:
		return

	var direction: PlayerFlip.Direction = player_flip.get_player_direction()
	var damage := int(stats.get("damage", WeaponHoldHandler.DEFAULT_DAMAGE))
	if active_slot == Enums.SlotType.MELEE:
		if fire_rate > 0.0:
			_next_shot_time_ms = now_ms + int(1000.0 / fire_rate)
		AudioManager.play_sfx(&"melee_stabbing")
		melee_attack_fired.emit()
		request_melee_attack.rpc_id(1, multiplayer.get_unique_id(), direction, damage)
		return

	if not weapon_hold_handler.consume_ammo():
		return
	if fire_rate > 0.0:
		_next_shot_time_ms = now_ms + int(1000.0 / fire_rate)
	_play_shoot_sfx(active_slot)

	# Calculate gun barrel position based on player direction
	var gun_barrel_position: Vector2 = Vector2()

	match direction:
		PlayerFlip.Direction.LEFT:
			gun_barrel_position = player.global_position - gun_barrel.position
		PlayerFlip.Direction.RIGHT:
			gun_barrel_position = player.global_position + gun_barrel.position

	shot_fired.emit()
	request_shoot.rpc_id(1, multiplayer.get_unique_id(), gun_barrel_position, direction, damage)


func _play_shoot_sfx(slot: String) -> void:
	match slot:
		Enums.SlotType.SECONDARY:
			AudioManager.play_sfx(&"secondary_shoot")
		_:
			AudioManager.play_sfx(&"primary_shoot")


@rpc("authority", "call_remote", "reliable")
func request_shoot(peer_id: int, pos: Vector2, direction: PlayerFlip.Direction, damage: int = BulletController.DEFAULT_DAMAGE) -> void:
	if not multiplayer.is_server(): return

	bullet_spawner.spawn({
		"peer_id": peer_id,
		"pos": pos,
		"direction": direction,
		"damage": damage,
	})


@rpc("authority", "call_remote", "reliable")
func request_melee_attack(peer_id: int, direction: PlayerFlip.Direction, damage: int = WeaponHoldHandler.DEFAULT_DAMAGE) -> void:
	if not multiplayer.is_server():
		return
	if peer_id != player.get_multiplayer_authority():
		return

	var query := PhysicsShapeQueryParameters2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(MELEE_RANGE, MELEE_HEIGHT)
	query.shape = shape
	query.collision_mask = 1
	query.exclude = [player.get_rid()]

	var x_offset := MELEE_RANGE * 0.5
	if direction == PlayerFlip.Direction.LEFT:
		x_offset = -x_offset
	query.transform = Transform2D(0.0, player.global_position + Vector2(x_offset, 0.0))

	var hits := player.get_world_2d().direct_space_state.intersect_shape(query, 8)
	var hit_players := {}
	for hit in hits:
		var body = hit.get("collider")
		if body is PlayerController and body.get_multiplayer_authority() != peer_id:
			var authority: int = body.get_multiplayer_authority()
			if hit_players.has(authority):
				continue
			hit_players[authority] = true
			body.get_node("PlayerHealth").take_damage_rpc.rpc_id(authority, damage)

			var knockback_dir := Vector2.RIGHT
			if direction == PlayerFlip.Direction.LEFT:
				knockback_dir = Vector2.LEFT
			body.get_node("PlayerKnockback").apply_bomb_force_rpc.rpc_id(
				authority,
				knockback_dir * MELEE_KNOCKBACK_FORCE
			)
