class_name GameManager extends Node2D

# ── Match context ──
var match_id: int = 0
var map_name: String = ""
var peer_to_player_id: Dictionary = {} # {int peer_id: String player_id}
var peer_to_name: Dictionary = {} # {int peer_id: String name}
var peer_to_weapons: Dictionary = {} # {int peer_id: Dictionary weapon_loadout {slot: {image, damage, fire_rate}}}
var peer_to_character: Dictionary = {} # {int peer_id: Dictionary character {texture, hp, run_speed}}

# ── In-match stats (server-only) ──
var kills: Dictionary = {} # {int peer_id: int count}
var deaths: Dictionary = {} # {int peer_id: int count}
var match_ended: bool = false
var _registered: bool = false

# ── Reward constants ──
const WINNER_GOLD := 50
const WINNER_EXP := 100
const WINNER_RANK_CHANGE := 15
const LOSER_GOLD := 20
const LOSER_EXP := 50
const LOSER_RANK_CHANGE := -10
const FORFEIT_RANK_CHANGE := -20

# ── Node references ──
@onready var player_spawner: PlayerSpawner = $World/PlayerSpawner
@onready var match_result_panel: MatchResultPanel = $CanvasLayer/Root/MatchResultOverlay


func _ready() -> void:
	if multiplayer.is_server():
		# Server: listen for player spawn and disconnect events
		player_spawner.player_spawned.connect(_on_player_spawned_server)
		player_spawner.player_disconnected.connect(_on_player_disconnected)
	else:
		# Client: send registration to server once connected
		match_id = NetworkManager.current_match_id
		_registered = false
		# Check if already connected (signal may have fired before this scene loaded)
		if multiplayer.has_multiplayer_peer() \
			and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			# Already connected — register after a short delay to let spawners initialize
			get_tree().create_timer(0.5).timeout.connect(_register_with_server)
		else:
			multiplayer.connected_to_server.connect(_register_with_server)
		# Handle server disconnect
		multiplayer.server_disconnected.connect(_on_server_disconnected)


func _register_with_server() -> void:
	if _registered: return
	_registered = true
	var player_name := NetworkManager.current_player_name
	if player_name == "":
		player_name = str(multiplayer.get_unique_id())
	var p_map_name := NetworkManager.current_map_name

	# Fetch own loadout (weapons + character) before registering
	_fetch_own_loadout(func(weapons: Dictionary, character: Dictionary):
		register_player.rpc_id(1, ApiManager.player_id, match_id, player_name, p_map_name, weapons, character)
	)


func _fetch_own_loadout(callback: Callable) -> void:
	var weapons := {}
	var character := {}
	var pending := {"count": 2}

	var maybe_done := func():
		pending["count"] -= 1
		if pending["count"] <= 0:
			callback.call(weapons, character)

	# Equipment (all weapon slots, including grenade; excluding character slot)
	PlayerApi.get_player_equipment(ApiManager.player_id, func(response: Dictionary):
		if not response.get("ok", false):
			maybe_done.call()
			return
		var equips = response.get("data", [])
		var weapon_pending := 0
		var any_started := false
		for equip in equips:
			var slot = equip.get("slot_type", "")
			var wid = int(equip.get("weapon_id", 0))
			if wid <= 0 or slot == Enums.SlotType.CHARACTER:
				continue
			weapon_pending += 1
			any_started = true
			_fetch_weapon_info(wid, slot, weapons, func():
				weapon_pending -= 1
				if weapon_pending == 0:
					maybe_done.call()
			)
		if not any_started:
			maybe_done.call()
	, true)

	# Selected character
	PlayerApi.get_selected_character(ApiManager.player_id, func(response: Dictionary):
		if not response.get("ok", false):
			maybe_done.call()
			return
		var data: Dictionary = response.get("data", {})
		var char_id := int(data.get("character_id", 0))
		if char_id <= 0:
			maybe_done.call()
			return
		ConfigApi.get_character(char_id, func(resp: Dictionary):
			if resp.get("ok", false):
				var cdata: Dictionary = resp.get("data", {})
				character["texture"] = cdata.get("texture", "")
				character["hp"] = int(cdata.get("hp", 0))
				character["run_speed"] = float(cdata.get("run_speed", 0.0))
			maybe_done.call()
		)
	, true)


func _fetch_weapon_info(weapon_id: int, slot_type: String, weapons: Dictionary, done: Callable) -> void:
	ConfigApi.get_weapon(weapon_id, func(resp: Dictionary):
		if resp.get("ok", false):
			var data: Dictionary = resp.get("data", {})
			weapons[slot_type] = {
				"image": data.get("image", ""),
				"damage": int(data.get("damage", 0)),
				"fire_rate": float(data.get("fire_rate", 0.0)),
				"ammo": int(data.get("ammo", 0)),
			}
		done.call()
	)


# ── Registration RPC (client → server) ──

@rpc("any_peer", "call_remote", "reliable")
func register_player(player_id: String, p_match_id: int, player_name: String, p_map_name: String = "", weapons: Dictionary = {}, character: Dictionary = {}) -> void:
	if not multiplayer.is_server(): return
	var sender := multiplayer.get_remote_sender_id()
	peer_to_player_id[sender] = player_id
	peer_to_name[sender] = player_name
	peer_to_weapons[sender] = weapons
	peer_to_character[sender] = character
	kills[sender] = 0
	deaths[sender] = 0
	if match_id == 0:
		match_id = p_match_id
	if map_name == "" and p_map_name != "":
		map_name = p_map_name

	# Once both peers have registered (their loadout dicts may be empty if
	# _fetch_own_loadout failed — instant-start flow), kick off the match.
	# PlayerSpawner.start_match bakes the loadout into spawn data so clients
	# instantiate players with full equipment from frame 1 (no 2s pop-in).
	if peer_to_name.size() >= 2:
		player_spawner.start_match(_build_peer_data())


func _build_peer_data() -> Dictionary:
	var out: Dictionary = {}
	for peer_id in peer_to_name:
		out[peer_id] = {
			"name": peer_to_name.get(peer_id, ""),
			"weapons": peer_to_weapons.get(peer_id, {}),
			"character": peer_to_character.get(peer_id, {}),
		}
	return out


# ── Server: Player spawned — connect health signals ──

func _on_player_spawned_server(player: Node) -> void:
	var health_node: PlayerHealth = player.get_node("PlayerHealth")

	health_node.player_died.connect(func(died_peer: int):
		_on_player_died(died_peer)
	)
	health_node.player_eliminated.connect(func(eliminated_peer: int):
		_on_player_eliminated(eliminated_peer)
	)


# ── Server: Kill/Death tracking ──

func _on_player_died(died_peer_id: int) -> void:
	deaths[died_peer_id] = deaths.get(died_peer_id, 0) + 1
	var killer_peer_id := _get_opponent_peer(died_peer_id)
	if killer_peer_id != -1:
		kills[killer_peer_id] = kills.get(killer_peer_id, 0) + 1


func _on_player_eliminated(eliminated_peer_id: int) -> void:
	if match_ended: return
	match_ended = true
	var winner_peer_id := _get_opponent_peer(eliminated_peer_id)
	_end_match(winner_peer_id, eliminated_peer_id, false)


# ── Server: Player disconnected (forfeit) ──

func _on_player_disconnected(peer_id: int) -> void:
	if match_ended: return
	# Only trigger forfeit if match has started (both players registered)
	if peer_to_player_id.size() < 2 and not peer_to_player_id.has(peer_id):
		return
	match_ended = true
	var winner_peer_id := _get_opponent_peer(peer_id)
	_end_match(winner_peer_id, peer_id, true)


# ── Server: End match — calculate rewards and notify clients ──

func _end_match(winner_peer: int, loser_peer: int, is_forfeit: bool) -> void:
	var winner_player_id: String = peer_to_player_id.get(winner_peer, "")
	var loser_player_id: String = peer_to_player_id.get(loser_peer, "")
	var winner_name: String = peer_to_name.get(winner_peer, str(winner_peer))
	var loser_name: String = peer_to_name.get(loser_peer, str(loser_peer))

	var result_data := {
		"match_id": match_id,
		"is_forfeit": is_forfeit,
		"players": {
			str(winner_peer): {
				"player_id": winner_player_id,
				"name": winner_name,
				"result": Enums.MatchResult.WIN,
				"kill": kills.get(winner_peer, 0),
				"dead": deaths.get(winner_peer, 0),
				"reward_gold": WINNER_GOLD,
				"exp_earned": WINNER_EXP,
				"rank_point_change": WINNER_RANK_CHANGE,
			},
			str(loser_peer): {
				"player_id": loser_player_id,
				"name": loser_name,
				"result": Enums.MatchResult.LOSE,
				"kill": kills.get(loser_peer, 0),
				"dead": deaths.get(loser_peer, 0),
				"reward_gold": 0 if is_forfeit else LOSER_GOLD,
				"exp_earned": 0 if is_forfeit else LOSER_EXP,
				"rank_point_change": FORFEIT_RANK_CHANGE if is_forfeit else LOSER_RANK_CHANGE,
			},
		}
	}

	# Send results to all connected clients
	_receive_match_result.rpc(result_data)

	# Schedule server cleanup
	await get_tree().create_timer(10.0).timeout
	_reset_server_state()


# ── Client: Receive match result via RPC ──

@rpc("authority", "call_remote", "reliable")
func _receive_match_result(result_data: Dictionary) -> void:
	if multiplayer.is_server(): return
	match_ended = true

	var my_peer := str(multiplayer.get_unique_id())
	var my_data: Dictionary = {}
	var opponent_data: Dictionary = {}

	var players: Dictionary = result_data.get("players", {})
	for peer_key in players:
		if peer_key == my_peer:
			my_data = players[peer_key]
		else:
			opponent_data = players[peer_key]

	# Hide gameplay UI
	var ui_controls = get_node_or_null("CanvasLayer/Root/UIControlPlayer")
	if ui_controls:
		ui_controls.visible = false
	var top_ui = get_node_or_null("CanvasLayer/Root/TopUI")
	if top_ui:
		top_ui.visible = false

	# Show result panel
	match_result_panel.show_result(my_data, opponent_data)


# ── Client: Server disconnected unexpectedly ──

func _on_server_disconnected() -> void:
	if match_ended:
		# Server disconnected after match ended normally — no error needed
		return
	# Unexpected disconnect — show error and return to lobby
	var global_ui = get_tree().root.get_node_or_null("Main/GlobalUi")
	if global_ui:
		global_ui.show_error_notification("Connection to server lost")
	await get_tree().create_timer(1.5).timeout
	NetworkManager.leave_game()


# ── Server: Reset for next match by reloading the game scene ──

func _reset_server_state() -> void:
	peer_to_player_id.clear()
	peer_to_name.clear()
	peer_to_weapons.clear()
	peer_to_character.clear()
	kills.clear()
	deaths.clear()
	match_id = 0
	match_ended = false
	# Reload entire game scene so all spawners start fresh
	SceneLoader.load_scene(NetworkManager.game_scene_path)


# ── Utility ──

func _get_opponent_peer(peer_id: int) -> int:
	for pid in peer_to_player_id:
		if pid != peer_id:
			return pid
	return -1
