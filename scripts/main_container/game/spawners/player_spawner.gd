class_name PlayerSpawner extends MultiplayerSpawner

@export var player_scene: PackedScene
var _players_list: Dictionary[int, Node] = {}
const MAX_PLAYER := 2
const SPAWN_X_OFFSET := 200

signal all_player_joined()
signal player_spawned(player: Node)
signal player_disconnected(peer_id: int)

func _ready():
	spawn_function = _spawn_player
	multiplayer.peer_connected.connect(_on_peer_connected)

	if multiplayer.is_server():
		set_multiplayer_authority(multiplayer.get_unique_id())
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(peer_id: int):
	if not multiplayer.is_server(): return
	_players_list.set(peer_id, null)
	# Spawn is triggered by GameManager.start_match() once both peers have
	# completed register_player (which carries their loadout). This guarantees
	# equipment is known before a player is ever instantiated.

# Called by GameManager (server-only) once both register_player RPCs have arrived.
# peer_data: { peer_id (int) -> { "name": String, "weapons": Dictionary, "character": Dictionary } }
func start_match(peer_data: Dictionary) -> void:
	if not multiplayer.is_server(): return

	# MapSpawner listens for this signal — fire it before spawning players so
	# the map is in place underneath them.
	all_player_joined.emit()

	var rng := RandomNumberGenerator.new()
	for peer_id in peer_data:
		var entry: Dictionary = peer_data[peer_id]
		self.spawn({
			"peer_id": peer_id,
			"pos": Vector2(rng.randf_range(-SPAWN_X_OFFSET, SPAWN_X_OFFSET), 0),
			"name": entry.get("name", ""),
			"weapons": entry.get("weapons", {}),
			"character": entry.get("character", {}),
		})

func _on_peer_disconnected(peer_id: int):
	if not multiplayer.is_server(): return

	player_disconnected.emit(peer_id)

	var player = _players_list.get(peer_id)
	if player:
		player.queue_free()
		_players_list.erase(peer_id)

# Runs on the server AND every client (MultiplayerSpawner replicates the spawn
# data dict). Equipment is applied here BEFORE the node is added to the tree,
# so the first _ready() (and the first _physics_process tick) sees the correct
# stats and weapon textures — no post-spawn pop-in.
func _spawn_player(data: Dictionary) -> Node:
	var player := player_scene.instantiate()
	player.set_multiplayer_authority(data["peer_id"])

	player.name = str(data["peer_id"])
	player.global_position = data["pos"]

	var character: Dictionary = data.get("character", {})
	var weapons: Dictionary = data.get("weapons", {})
	var display_name: String = data.get("name", "")
	var is_own: bool = data["peer_id"] == multiplayer.get_unique_id()

	# Stash values that PlayerController applies in _ready (after @onready vars
	# resolve): the display name label and the character sprite texture.
	if display_name != "":
		player.set_meta("display_name", display_name)
	var texture_name: String = character.get("texture", "")
	if texture_name != "":
		player.set_meta("character_texture_name", texture_name)

	# Owning-peer stats: empty / zero values fall through to the DEFAULT_*
	# constants in each component.
	if is_own:
		# HP: stashed as metadata and applied in PlayerHealth._ready().
		# set_max_health writes to the `health` var, whose setter calls
		# is_multiplayer_authority() — illegal before the node enters the tree.
		var hp := int(character.get("hp", 0))
		if hp > 0:
			player.get_node("PlayerHealth").set_meta("pending_max_health", hp)
		# set_speed is a plain var assignment — safe pre-tree.
		var run_speed_mult := float(character.get("run_speed", 0.0))
		if run_speed_mult > 0.0:
			player.get_node("PlayerMovement").set_speed(PlayerMovement.DEFAULT_SPEED * run_speed_mult)
		# set_grenade_damage is a plain var assignment — safe pre-tree.
		var grenade: Dictionary = weapons.get(Enums.SlotType.GRENADE, {})
		var grenade_damage := int(grenade.get("damage", 0))
		if grenade_damage > 0:
			player.set_grenade_damage(grenade_damage)

	# Weapon textures + stats (visible on every peer). set_weapon_loadout only
	# touches $Primary/$Secondary/$Melee siblings + a stats dict — safe pre-tree.
	if not weapons.is_empty():
		var weapon_handler = player.get_node_or_null("ChracterSprites/WeaponHoldHandler")
		if weapon_handler:
			weapon_handler.set_weapon_loadout(weapons)

	# Local UI wiring on the owning client; opponent label on the other client.
	if is_own:
		# Bind even when `weapons` is empty (instant-start). The bind sets the
		# weapon-handler ref and connects ammo_changed; WeaponHoldHandler._ready
		# seeds default ammo for the owning player when no loadout was applied,
		# so the bottom CurrentWeaponBtn still shows "mag/reserve" text.
		var switch_handler = get_tree().root.get_node_or_null("Main/SceneContainer/Game/CanvasLayer/Root/UIControlPlayer/SwitchWeaponHandler")
		var weapon_handler2 = player.get_node_or_null("ChracterSprites/WeaponHoldHandler")
		if switch_handler and weapon_handler2 and switch_handler.has_method("bind_local_player"):
			switch_handler.bind_local_player(weapon_handler2, weapons)
	else:
		if display_name != "":
			var opponent_label = get_tree().root.get_node_or_null("Main/SceneContainer/Game/CanvasLayer/Root/TopUI/OpponentInfor/Name")
			if opponent_label:
				opponent_label.text = display_name

	_players_list[data["peer_id"]] = player

	player_spawned.emit(player)

	return player
