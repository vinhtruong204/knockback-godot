class_name GameManager extends Node2D

# ── Match context ──
var match_id: int = 0
var map_name: String = ""
var game_mode: String = "rank"
var mode_code: String = NetworkManager.MODE_CODE_RANKED_FREE_FOR_ALL
var peer_to_player_id: Dictionary = {} # {int peer_id: String player_id}
var peer_to_name: Dictionary = {} # {int peer_id: String name}
var peer_to_weapons: Dictionary = {} # {int peer_id: Dictionary weapon_loadout {slot: {image, damage, fire_rate}}}
var peer_to_character: Dictionary = {} # {int peer_id: Dictionary character {texture, hp, run_speed}}
var peer_to_team: Dictionary = {} # {int peer_id: int team_id}

# ── In-match stats (server-only) ──
var kills: Dictionary = {} # {int peer_id: int count}
var deaths: Dictionary = {} # {int peer_id: int count}
var match_ended: bool = false
var match_started: bool = false
var _registered: bool = false

# ── Reward constants ──
const WINNER_GOLD := 50
const WINNER_EXP := 100
const WINNER_RANK_CHANGE := 15
const LOSER_GOLD := 20
const LOSER_EXP := 50
const LOSER_RANK_CHANGE := -10
const FORFEIT_RANK_CHANGE := -20

const SD_TOTAL_ROUNDS := 3
const SD_WIN_TARGET := 2
const SD_ROUND_TIME := 90.0
const SD_PLANT_HOLD := 2.0
const SD_DEFUSE_HOLD := 3.0
const SD_BOMB_TIME := 30.0
const SD_INTERACT_RADIUS := 90.0
const SD_C4_BLAST_RADIUS := 260.0
const SD_C4_MAX_DAMAGE := 80
const SD_C4_MAX_FORCE := 320.0
const SD_ATTACKER_TEAM := 1
const SD_DEFENDER_TEAM := 2
const SD_SITE_PLATFORM_Y_OFFSET := 22.0
const SD_FALLBACK_SITE_POSITIONS: Array[Vector2] = [
	Vector2(-520, 180),
	Vector2(0, 90),
	Vector2(520, 180),
]
const SD_SITE_LABELS: Array[String] = ["A", "B", "C"]
const SD_OBJECTIVE_ICON: Texture2D = preload("res://assets/game/search_destroy/objective_bomb_icon.png")

enum SearchDestroyState { DISABLED, PRE_ROUND, LIVE, PLANTING, PLANTED, DEFUSING, ROUND_OVER, MATCH_OVER }

var sd_state: int = SearchDestroyState.DISABLED
var sd_round_index: int = 0
var sd_scores: Dictionary = {1: 0, 2: 0}
var sd_round_time_left: float = SD_ROUND_TIME
var sd_bomb_time_left: float = SD_BOMB_TIME
var sd_active_site_index: int = 0
var sd_active_site_position: Vector2 = Vector2.ZERO
var sd_interacting_peer: int = -1
var sd_interaction_type: String = ""
var sd_interaction_progress: float = 0.0
var sd_hud_sync_accum: float = 0.0
var sd_last_bomb_tick_second: int = -1
var sd_site_positions: Array[Vector2] = []
var _sd_marker_nodes: Array[Node2D] = []

# ── Node references ──
@onready var player_spawner: PlayerSpawner = $World/PlayerSpawner
@onready var map_spawner: MapSpawner = $World/MapSpawner
@onready var match_result_panel: MatchResultPanel = $CanvasLayer/Root/MatchResultOverlay


func _ready() -> void:
	AudioManager.play_music(&"ingame")
	AudioManager.bind_button_sfx($CanvasLayer/Root)
	game_mode = NetworkManager.current_game_mode
	mode_code = NetworkManager.current_mode_code
	map_spawner.map_spawned.connect(_on_map_spawned)
	_build_search_destroy_hud()
	_build_search_destroy_sites()
	_bind_search_destroy_objective_controls()
	if multiplayer.is_server():
		# Server: listen for player spawn and disconnect events
		player_spawner.player_spawned.connect(_on_player_spawned_server)
		player_spawner.player_disconnected.connect(_on_player_disconnected)
		if NetworkManager.current_game_mode == NetworkManager.GAME_MODE_LAN and NetworkManager.is_lan_host_player:
			get_tree().create_timer(0.3).timeout.connect(_register_lan_host_player)
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


func _physics_process(delta: float) -> void:
	if multiplayer.is_server() and _is_search_destroy_mode() and match_started and not match_ended:
		_process_search_destroy(delta)


func _register_with_server() -> void:
	if _registered: return
	_registered = true
	var player_name := NetworkManager.current_player_name
	if player_name == "":
		player_name = str(multiplayer.get_unique_id())
	var p_map_name := NetworkManager.current_map_key
	if p_map_name == "":
		p_map_name = NetworkManager.current_map_name

	# Fetch own loadout (weapons + character) before registering.
	_fetch_loadout_for_player(ApiManager.player_id, func(weapons: Dictionary, character: Dictionary):
		register_player.rpc_id(
			1,
			ApiManager.player_id,
			match_id,
			player_name,
			p_map_name,
			weapons,
			character,
			NetworkManager.current_game_mode,
			NetworkManager.current_mode_code,
			NetworkManager.current_match_players
		)
	)


func _register_lan_host_player() -> void:
	if _registered: return
	_registered = true
	match_id = 0
	var player_name := NetworkManager.current_player_name
	if player_name == "":
		player_name = str(multiplayer.get_unique_id())
	var p_map_name := NetworkManager.current_map_key
	if p_map_name == "":
		p_map_name = NetworkManager.current_map_name

	_fetch_loadout_for_player(ApiManager.player_id, func(weapons: Dictionary, character: Dictionary):
		_register_player_for_peer(multiplayer.get_unique_id(), ApiManager.player_id, match_id, player_name, p_map_name, weapons, character, NetworkManager.GAME_MODE_LAN, NetworkManager.GAME_MODE_LAN, [])
	)


func _fetch_loadout_for_player(player_id: String, callback: Callable) -> void:
	var weapons := {}
	var character := {}
	var pending := {"count": 2}

	var maybe_done := func():
		pending["count"] -= 1
		if pending["count"] <= 0:
			callback.call(weapons, character)

	# Equipment (all weapon slots, including grenade; excluding character slot)
	PlayerApi.get_player_equipment(player_id, func(response: Dictionary):
		if not response.get("ok", false):
			print("[GameManager] Failed to fetch equipment for player ", player_id, ": ", response.get("error", "unknown error"))
			maybe_done.call()
			return
		var equips = response.get("data", [])
		var weapon_pending := {"count": 0}
		var any_started := false
		for equip in equips:
			var slot_type := str(equip.get("slot_type", ""))
			var weapon_id := int(equip.get("weapon_id", 0))
			if weapon_id <= 0 or slot_type == Enums.SlotType.CHARACTER:
				continue
			weapon_pending["count"] += 1
			any_started = true
			_fetch_weapon_info(weapon_id, slot_type, weapons, func():
				weapon_pending["count"] -= 1
				if weapon_pending["count"] == 0:
					maybe_done.call()
			)
		if not any_started:
			maybe_done.call()
	, true)

	# Selected character
	PlayerApi.get_selected_character(player_id, func(response: Dictionary):
		if not response.get("ok", false):
			print("[GameManager] Failed to fetch selected character for player ", player_id, ": ", response.get("error", "unknown error"))
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
			else:
				print("[GameManager] Failed to fetch character config ", char_id, " for player ", player_id, ": ", resp.get("error", "unknown error"))
			maybe_done.call()
		)
	, true)


func _fetch_weapon_info(weapon_id: int, slot_type: String, weapons: Dictionary, done: Callable) -> void:
	ConfigApi.get_weapon(weapon_id, func(resp: Dictionary):
		if resp.get("ok", false):
			var data: Dictionary = resp.get("data", {})
			weapons[slot_type] = {
				"weapon_id": weapon_id,
				"slot_type": slot_type,
				"image": data.get("image", ""),
				"damage": int(data.get("damage", 0)),
				"fire_rate": float(data.get("fire_rate", 0.0)),
				"ammo": int(data.get("ammo", 0)),
			}
		else:
			print("[GameManager] Failed to fetch weapon config ", weapon_id, " for slot ", slot_type, ": ", resp.get("error", "unknown error"))
		done.call()
	, true)


# ── Registration RPC (client → server) ──

@rpc("any_peer", "call_remote", "reliable")
func register_player(player_id: String, p_match_id: int, player_name: String, p_map_name: String = "", weapons: Dictionary = {}, character: Dictionary = {}, p_game_mode: String = "", p_mode_code: String = "", match_players: Array = []) -> void:
	if not multiplayer.is_server(): return
	var sender := multiplayer.get_remote_sender_id()
	_register_player_for_peer(sender, player_id, p_match_id, player_name, p_map_name, weapons, character, p_game_mode, p_mode_code, match_players)


func _register_player_for_peer(peer_id: int, player_id: String, p_match_id: int, player_name: String, p_map_name: String = "", weapons: Dictionary = {}, character: Dictionary = {}, p_game_mode: String = "", p_mode_code: String = "", match_players: Array = []) -> void:
	if not multiplayer.is_server(): return
	if match_started:
		print("[GameManager] Ignoring registration after match start for peer ", peer_id)
		return

	peer_to_player_id[peer_id] = player_id
	peer_to_name[peer_id] = player_name
	peer_to_weapons[peer_id] = weapons
	peer_to_character[peer_id] = character
	peer_to_team[peer_id] = _resolve_team_for_player(player_id, match_players, peer_id)
	kills[peer_id] = 0
	deaths[peer_id] = 0
	print("[GameManager] Registered peer ", peer_id, " player ", player_id, " name ", player_name, " weapons ", weapons)
	if weapons.is_empty():
		print("[GameManager] Empty weapon loadout for peer ", peer_id, " player ", player_id, "; using defaults")
	if character.is_empty():
		print("[GameManager] Empty character loadout for peer ", peer_id, " player ", player_id, "; using defaults")
	if match_id == 0:
		match_id = p_match_id
	if map_name == "" and p_map_name != "":
		map_name = p_map_name
	if p_game_mode != "":
		game_mode = p_game_mode
	if p_mode_code != "":
		mode_code = p_mode_code

	# Once both peers have registered (their loadout dicts may be empty if
	# loadout fetch failed, kick off the match with fallback defaults.
	# PlayerSpawner.start_match bakes the loadout into spawn data so clients
	# instantiate players with full equipment from frame 1 (no 2s pop-in).
	if peer_to_name.size() >= PlayerSpawner.MAX_PLAYER and not match_started:
		match_started = true
		player_spawner.start_match(_build_peer_data())
		if _is_search_destroy_mode():
			_start_search_destroy_match()


func _build_peer_data() -> Dictionary:
	var out: Dictionary = {}
	for peer_id in peer_to_name:
		out[peer_id] = {
			"name": peer_to_name.get(peer_id, ""),
			"team_id": int(peer_to_team.get(peer_id, 0)),
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
	var winner_peer_id := _get_opponent_peer(eliminated_peer_id)
	if winner_peer_id == -1:
		return
	if _is_search_destroy_mode():
		var winning_team := int(peer_to_team.get(winner_peer_id, SD_ATTACKER_TEAM))
		sd_state = SearchDestroyState.MATCH_OVER
		sd_scores[winning_team] = min(SD_WIN_TARGET, int(sd_scores.get(winning_team, 0)) + 1)
		match_ended = true
		_sd_show_round_banner.rpc(winning_team, "hearts")
		_sd_sync_state()
		_end_match(winner_peer_id, eliminated_peer_id, false)
		return
	match_ended = true
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
	var rewards_enabled := game_mode != NetworkManager.GAME_MODE_LAN
	var rank_enabled := game_mode == NetworkManager.GAME_MODE_RANK
	var winner_score := _get_team_score(int(peer_to_team.get(winner_peer, SD_ATTACKER_TEAM)))
	var loser_score := _get_team_score(int(peer_to_team.get(loser_peer, SD_DEFENDER_TEAM)))

	var result_data := {
		"match_id": match_id,
		"is_forfeit": is_forfeit,
		"game_mode": game_mode,
		"players": {
			str(winner_peer): {
				"player_id": winner_player_id,
				"name": winner_name,
				"result": Enums.MatchResult.WIN,
				"kill": kills.get(winner_peer, 0),
				"dead": deaths.get(winner_peer, 0),
				"score": winner_score,
				"reward_gold": WINNER_GOLD if rewards_enabled else 0,
				"exp_earned": WINNER_EXP if rewards_enabled else 0,
				"rank_point_change": WINNER_RANK_CHANGE if rank_enabled else 0,
			},
			str(loser_peer): {
				"player_id": loser_player_id,
				"name": loser_name,
				"result": Enums.MatchResult.LOSE,
				"kill": kills.get(loser_peer, 0),
				"dead": deaths.get(loser_peer, 0),
				"score": loser_score,
				"reward_gold": 0 if is_forfeit or not rewards_enabled else LOSER_GOLD,
				"exp_earned": 0 if is_forfeit or not rewards_enabled else LOSER_EXP,
				"rank_point_change": (FORFEIT_RANK_CHANGE if is_forfeit else LOSER_RANK_CHANGE) if rank_enabled else 0,
			},
		}
	}

	# Send results to all connected clients
	_receive_match_result.rpc(result_data)
	if game_mode == NetworkManager.GAME_MODE_LAN and NetworkManager.is_lan_host_player:
		_receive_match_result(result_data)

	# Schedule server cleanup
	if game_mode != NetworkManager.GAME_MODE_LAN:
		await get_tree().create_timer(10.0).timeout
		_reset_server_state()


# ── Client: Receive match result via RPC ──

@rpc("authority", "call_remote", "reliable")
func _receive_match_result(result_data: Dictionary) -> void:
	if multiplayer.is_server() and not (game_mode == NetworkManager.GAME_MODE_LAN and NetworkManager.is_lan_host_player):
		return
	match_ended = true
	AudioManager.play_music(&"lobby")

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
	peer_to_team.clear()
	kills.clear()
	deaths.clear()
	match_id = 0
	match_ended = false
	match_started = false
	mode_code = NetworkManager.MODE_CODE_RANKED_FREE_FOR_ALL
	sd_state = SearchDestroyState.DISABLED
	# Reload entire game scene so all spawners start fresh
	SceneLoader.load_scene(NetworkManager.game_scene_path)


# ── Utility ──

# Search & Destroy

func _is_search_destroy_mode() -> bool:
	return NetworkManager.is_search_destroy_mode(mode_code)


func _build_search_destroy_hud() -> void:
	var top_ui := get_node_or_null("CanvasLayer/Root/TopUI") as Control
	if top_ui and top_ui.get_node_or_null("SearchDestroyHud") == null:
		var hud := Panel.new()
		hud.name = "SearchDestroyHud"
		hud.visible = false
		hud.set_anchors_preset(Control.PRESET_TOP_WIDE)
		hud.anchor_left = 0.32
		hud.anchor_right = 0.68
		hud.offset_top = 4.0
		hud.offset_bottom = 94.0
		top_ui.add_child(hud)

		var icon := TextureRect.new()
		icon.name = "ObjectiveIcon"
		icon.texture = SD_OBJECTIVE_ICON
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.position = Vector2(8.0, 8.0)
		icon.size = Vector2(42.0, 42.0)
		hud.add_child(icon)

		var box := VBoxContainer.new()
		box.name = "Box"
		box.set_anchors_preset(Control.PRESET_FULL_RECT)
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_theme_constant_override("separation", 0)
		hud.add_child(box)

		for label_name in ["ScoreLabel", "RoundLabel", "TimerLabel", "StatusLabel"]:
			var label := Label.new()
			label.name = label_name
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 17 if label_name != "ScoreLabel" else 20)
			box.add_child(label)

		var interaction_progress := ProgressBar.new()
		interaction_progress.name = "InteractionProgress"
		interaction_progress.visible = false
		interaction_progress.min_value = 0.0
		interaction_progress.max_value = 100.0
		interaction_progress.value = 0.0
		interaction_progress.show_percentage = false
		interaction_progress.custom_minimum_size = Vector2(180.0, 8.0)
		box.add_child(interaction_progress)

	var root := get_node_or_null("CanvasLayer/Root") as Control
	if root and root.get_node_or_null("SearchDestroyRoundBanner") == null:
		var banner := Label.new()
		banner.name = "SearchDestroyRoundBanner"
		banner.visible = false
		banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
		banner.anchor_left = 0.2
		banner.anchor_right = 0.8
		banner.offset_top = 86.0
		banner.offset_bottom = 132.0
		banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		banner.add_theme_font_size_override("font_size", 30)
		banner.add_theme_color_override("font_color", Color(1.0, 0.83, 0.26))
		root.add_child(banner)


func _build_search_destroy_sites() -> void:
	var world := get_node_or_null("World") as Node2D
	if world == null or world.get_node_or_null("SearchDestroySites") != null:
		return
	var sites := Node2D.new()
	sites.name = "SearchDestroySites"
	world.add_child(sites)
	var positions: Array[Vector2] = _get_search_destroy_site_positions()
	for i in range(positions.size()):
		var marker := SearchDestroySiteMarker.new()
		marker.name = "Site%d" % (i + 1)
		marker.position = positions[i]
		marker.site_label = SD_SITE_LABELS[i]
		marker.active = false
		sites.add_child(marker)
		_sd_marker_nodes.append(marker)


func _bind_search_destroy_objective_controls() -> void:
	var buttons := get_node_or_null("CanvasLayer/Root/UIControlPlayer/ButtonsWrapper") as ButtonsControlPlayer
	if buttons == null:
		return
	if not buttons.c4_pressed.is_connected(_on_c4_pressed):
		buttons.c4_pressed.connect(_on_c4_pressed)
	if not buttons.c4_released.is_connected(_on_c4_released):
		buttons.c4_released.connect(_on_c4_released)


func _on_c4_pressed() -> void:
	var player := player_spawner.get_player(multiplayer.get_unique_id()) as PlayerController
	if player == null:
		return
	try_start_search_destroy_interaction(player)


func _on_c4_released() -> void:
	stop_search_destroy_interaction()


func try_start_search_destroy_interaction(player: PlayerController) -> bool:
	if not _is_search_destroy_mode():
		return false
	if not _sd_local_can_interact(player):
		return false
	if multiplayer.is_server():
		return _sd_try_start_interaction_for_peer(multiplayer.get_unique_id())
	request_search_destroy_interaction_start.rpc_id(1)
	return true


func stop_search_destroy_interaction() -> void:
	if not _is_search_destroy_mode():
		return
	if multiplayer.is_server():
		if multiplayer.get_unique_id() == sd_interacting_peer:
			_sd_cancel_interaction()
		return
	request_search_destroy_interaction_stop.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func request_search_destroy_interaction_start() -> void:
	if not multiplayer.is_server() or not _is_search_destroy_mode():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	_sd_try_start_interaction_for_peer(peer_id)


func _sd_try_start_interaction_for_peer(peer_id: int) -> bool:
	var interaction := _sd_interaction_for_peer(peer_id)
	if interaction == "":
		return false
	sd_interacting_peer = peer_id
	sd_interaction_type = interaction
	sd_interaction_progress = 0.0
	sd_state = SearchDestroyState.PLANTING if interaction == "plant" else SearchDestroyState.DEFUSING
	_sd_sync_state()
	return true


@rpc("any_peer", "call_remote", "reliable")
func request_search_destroy_interaction_stop() -> void:
	if not multiplayer.is_server() or not _is_search_destroy_mode():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if peer_id != sd_interacting_peer:
		return
	_sd_cancel_interaction()


func _on_map_spawned(map: Node) -> void:
	if not _is_search_destroy_mode():
		return
	sd_site_positions = _select_search_destroy_site_positions(_collect_search_destroy_site_candidates(map))
	if multiplayer.is_server():
		_sd_sync_sites_rpc.rpc(sd_site_positions)
	_sd_update_site_markers()


func _ensure_search_destroy_sites_ready() -> void:
	if sd_site_positions.size() >= SD_SITE_LABELS.size():
		return
	var map: Node = get_node_or_null("World/MapSpawner/MapSpawnPoint/Map")
	if map != null:
		sd_site_positions = _select_search_destroy_site_positions(_collect_search_destroy_site_candidates(map))
	else:
		sd_site_positions = _select_search_destroy_site_positions([])


func _collect_search_destroy_site_candidates(map: Node) -> Array[Vector2]:
	var candidates: Array[Vector2] = []
	var platforms_parent: Node = map.get_node_or_null("Platforms")
	if platforms_parent == null:
		return candidates
	_collect_platform_site_candidates_recursive(platforms_parent, candidates)
	return candidates


func _collect_platform_site_candidates_recursive(node: Node, candidates: Array[Vector2]) -> void:
	if node is StaticBody2D and bool(node.get_meta("is_bottom_platform", false)):
		return
	if node is CollisionShape2D:
		var collision_shape := node as CollisionShape2D
		if collision_shape.shape is RectangleShape2D:
			var rectangle_shape := collision_shape.shape as RectangleShape2D
			candidates.append(collision_shape.global_position + Vector2(0.0, -rectangle_shape.size.y * 0.5 - SD_SITE_PLATFORM_Y_OFFSET))
	for child: Node in node.get_children():
		_collect_platform_site_candidates_recursive(child, candidates)


func _select_search_destroy_site_positions(candidates: Array[Vector2]) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	if candidates.is_empty():
		positions.append_array(SD_FALLBACK_SITE_POSITIONS)
		return positions

	candidates.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return a.x < b.x
	)

	var indexes: Array[int] = []
	if candidates.size() == 1:
		indexes = [0, 0, 0]
	elif candidates.size() == 2:
		indexes = [0, 0, 1]
	else:
		indexes = [0, int(floori(candidates.size() / 2)), candidates.size() - 1]

	for index in indexes:
		positions.append(candidates[index])
	return positions


func _get_search_destroy_site_positions() -> Array[Vector2]:
	if sd_site_positions.size() >= SD_SITE_LABELS.size():
		return sd_site_positions
	return SD_FALLBACK_SITE_POSITIONS


@rpc("authority", "call_local", "reliable")
func _sd_sync_sites_rpc(site_positions: Array) -> void:
	var incoming_positions: Array = site_positions.duplicate()
	sd_site_positions.clear()
	for item in incoming_positions:
		if item is Vector2:
			sd_site_positions.append(item)
	sd_site_positions = _select_search_destroy_site_positions(sd_site_positions)
	_sd_update_site_markers()


func _start_search_destroy_match() -> void:
	_ensure_search_destroy_sites_ready()
	_sd_sync_sites_rpc.rpc(sd_site_positions)
	sd_scores = {1: 0, 2: 0}
	sd_round_index = 0
	sd_state = SearchDestroyState.PRE_ROUND
	_sd_start_next_round()


func _sd_start_next_round() -> void:
	if match_ended:
		return
	var positions: Array[Vector2] = _get_search_destroy_site_positions()
	sd_round_index += 1
	sd_active_site_index = (sd_round_index - 1) % positions.size()
	sd_active_site_position = positions[sd_active_site_index]
	sd_round_time_left = SD_ROUND_TIME
	sd_bomb_time_left = SD_BOMB_TIME
	sd_interacting_peer = -1
	sd_interaction_type = ""
	sd_interaction_progress = 0.0
	sd_last_bomb_tick_second = -1
	sd_state = SearchDestroyState.LIVE
	_sd_sync_state()


func _process_search_destroy(delta: float) -> void:
	match sd_state:
		SearchDestroyState.LIVE:
			sd_round_time_left -= delta
			if sd_round_time_left <= 0.0:
				_sd_finish_round(SD_DEFENDER_TEAM, "timeout")
		SearchDestroyState.PLANTING:
			sd_round_time_left -= delta
			if sd_round_time_left <= 0.0:
				_sd_finish_round(SD_DEFENDER_TEAM, "timeout")
				return
			if not _sd_can_continue_interaction(sd_interacting_peer, "plant"):
				_sd_cancel_interaction()
				return
			sd_interaction_progress += delta
			if sd_interaction_progress >= SD_PLANT_HOLD:
				_sd_complete_plant()
		SearchDestroyState.PLANTED:
			sd_bomb_time_left -= delta
			_sd_maybe_play_bomb_tick()
			if sd_bomb_time_left <= 0.0:
				_sd_finish_round(SD_ATTACKER_TEAM, "detonated")
		SearchDestroyState.DEFUSING:
			sd_bomb_time_left -= delta
			_sd_maybe_play_bomb_tick()
			if sd_bomb_time_left <= 0.0:
				_sd_finish_round(SD_ATTACKER_TEAM, "detonated")
				return
			if not _sd_can_continue_interaction(sd_interacting_peer, "defuse"):
				_sd_cancel_interaction()
				return
			sd_interaction_progress += delta
			if sd_interaction_progress >= SD_DEFUSE_HOLD:
				_sd_complete_defuse()

	sd_hud_sync_accum += delta
	if sd_hud_sync_accum >= 0.25:
		sd_hud_sync_accum = 0.0
		_sd_sync_state()


func _sd_complete_plant() -> void:
	sd_state = SearchDestroyState.PLANTED
	sd_bomb_time_left = SD_BOMB_TIME
	sd_interacting_peer = -1
	sd_interaction_type = ""
	sd_interaction_progress = 0.0
	sd_last_bomb_tick_second = int(ceil(sd_bomb_time_left))
	_sd_play_objective_sfx.rpc("sd_planted")
	_sd_sync_state()


func _sd_complete_defuse() -> void:
	_sd_play_objective_sfx.rpc("sd_defuse")
	_sd_finish_round(SD_DEFENDER_TEAM, "defused")


func _sd_maybe_play_bomb_tick() -> void:
	var tick_second := int(ceil(sd_bomb_time_left))
	if tick_second == sd_last_bomb_tick_second:
		return
	sd_last_bomb_tick_second = tick_second
	_sd_play_objective_sfx.rpc("sd_bomb_tick")


func _sd_cancel_interaction() -> void:
	if sd_state == SearchDestroyState.PLANTING:
		sd_state = SearchDestroyState.LIVE
	elif sd_state == SearchDestroyState.DEFUSING:
		sd_state = SearchDestroyState.PLANTED
	sd_interacting_peer = -1
	sd_interaction_type = ""
	sd_interaction_progress = 0.0
	_sd_sync_state()


func _sd_finish_round(winning_team: int, reason: String) -> void:
	if sd_state == SearchDestroyState.ROUND_OVER or sd_state == SearchDestroyState.MATCH_OVER or match_ended:
		return
	sd_state = SearchDestroyState.ROUND_OVER
	sd_scores[winning_team] = int(sd_scores.get(winning_team, 0)) + 1
	if reason == "detonated":
		_sd_play_explosion_effect.rpc(sd_active_site_position)
		_sd_apply_c4_blast(sd_active_site_position)
	_sd_show_round_banner.rpc(winning_team, reason)
	_sd_sync_state()

	if int(sd_scores.get(winning_team, 0)) >= SD_WIN_TARGET or sd_round_index >= SD_TOTAL_ROUNDS:
		sd_state = SearchDestroyState.MATCH_OVER
		match_ended = true
		var winner_peer := _get_peer_for_team(winning_team)
		var loser_peer := _get_opponent_peer(winner_peer)
		_end_match(winner_peer, loser_peer, false)
		return

	await get_tree().create_timer(2.0).timeout
	_sd_start_next_round()


func _sd_interaction_for_peer(peer_id: int) -> String:
	if peer_id <= 0:
		return ""
	var player := player_spawner.get_player(peer_id) as PlayerController
	if player == null:
		return ""
	if player.global_position.distance_to(sd_active_site_position) > SD_INTERACT_RADIUS:
		return ""
	var team := int(peer_to_team.get(peer_id, 0))
	if sd_state == SearchDestroyState.LIVE and team == SD_ATTACKER_TEAM:
		return "plant"
	if sd_state == SearchDestroyState.PLANTED and team == SD_DEFENDER_TEAM:
		return "defuse"
	return ""


func _sd_can_continue_interaction(peer_id: int, interaction_type: String) -> bool:
	if peer_id <= 0:
		return false
	var player := player_spawner.get_player(peer_id) as PlayerController
	if player == null:
		return false
	if player.global_position.distance_to(sd_active_site_position) > SD_INTERACT_RADIUS:
		return false
	var team := int(peer_to_team.get(peer_id, 0))
	if interaction_type == "plant":
		return sd_state == SearchDestroyState.PLANTING and team == SD_ATTACKER_TEAM
	if interaction_type == "defuse":
		return sd_state == SearchDestroyState.DEFUSING and team == SD_DEFENDER_TEAM
	return false


func _sd_apply_c4_blast(blast_center: Vector2) -> void:
	if not multiplayer.is_server():
		return
	for peer_id in peer_to_player_id.keys():
		var player: PlayerController = player_spawner.get_player(int(peer_id)) as PlayerController
		if player == null:
			continue
		var offset: Vector2 = player.global_position - blast_center
		var distance: float = offset.length()
		if distance > SD_C4_BLAST_RADIUS:
			continue
		var falloff: float = 1.0 - (distance / SD_C4_BLAST_RADIUS)
		var damage: int = int(round(float(SD_C4_MAX_DAMAGE) * falloff))
		var direction: Vector2 = offset.normalized()
		if direction == Vector2.ZERO:
			direction = Vector2(0.7, -0.7).normalized()
		var force: Vector2 = direction * (SD_C4_MAX_FORCE * falloff)
		_sd_apply_c4_damage_and_force(player, damage, force)


func _sd_apply_c4_damage_and_force(player: PlayerController, damage: int, force: Vector2) -> void:
	var authority: int = player.get_multiplayer_authority()
	var health: PlayerHealth = player.get_node_or_null("PlayerHealth") as PlayerHealth
	var knockback: PlayerKnockback = player.get_node_or_null("PlayerKnockback") as PlayerKnockback
	if health and damage > 0:
		if authority == multiplayer.get_unique_id():
			health.take_damage_rpc(damage)
		else:
			health.take_damage_rpc.rpc_id(authority, damage)
	if knockback and force.length_squared() > 0.0:
		if authority == multiplayer.get_unique_id():
			knockback.apply_bomb_force_rpc(force)
		else:
			knockback.apply_bomb_force_rpc.rpc_id(authority, force)


func _sd_local_can_interact(player: PlayerController) -> bool:
	if player == null:
		return false
	if player.global_position.distance_to(sd_active_site_position) > SD_INTERACT_RADIUS:
		return false
	var team := _get_local_team()
	if sd_state == SearchDestroyState.LIVE and team == SD_ATTACKER_TEAM:
		return true
	if sd_state == SearchDestroyState.PLANTED and team == SD_DEFENDER_TEAM:
		return true
	return false


func _sd_sync_state() -> void:
	_sd_sync_state_rpc.rpc(
		int(sd_state),
		sd_round_index,
		int(sd_scores.get(SD_ATTACKER_TEAM, 0)),
		int(sd_scores.get(SD_DEFENDER_TEAM, 0)),
		sd_round_time_left,
		sd_bomb_time_left,
		sd_active_site_index,
		sd_active_site_position,
		sd_interacting_peer,
		sd_interaction_type,
		sd_interaction_progress
	)


@rpc("authority", "call_local", "reliable")
func _sd_sync_state_rpc(state_value: int, round_index: int, attacker_score: int, defender_score: int, round_time: float, bomb_time: float, site_index: int, site_position: Vector2, interacting_peer: int, interaction_type: String, interaction_progress: float) -> void:
	sd_state = state_value
	sd_round_index = round_index
	sd_scores[SD_ATTACKER_TEAM] = attacker_score
	sd_scores[SD_DEFENDER_TEAM] = defender_score
	sd_round_time_left = round_time
	sd_bomb_time_left = bomb_time
	sd_active_site_index = site_index
	sd_active_site_position = site_position
	sd_interacting_peer = interacting_peer
	sd_interaction_type = interaction_type
	sd_interaction_progress = interaction_progress
	_sd_update_site_markers()
	_sd_refresh_hud()


@rpc("authority", "call_local", "reliable")
func _sd_show_round_banner(winning_team: int, reason: String) -> void:
	var banner := get_node_or_null("CanvasLayer/Root/SearchDestroyRoundBanner") as Label
	if banner == null:
		return
	banner.text = _sd_round_banner_text(winning_team, reason)
	banner.visible = true
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(banner):
		banner.visible = false


@rpc("authority", "call_local", "reliable")
func _sd_play_objective_sfx(sound_key: String) -> void:
	AudioManager.play_sfx(StringName(sound_key))


@rpc("authority", "call_local", "reliable")
func _sd_play_explosion_effect(effect_position: Vector2) -> void:
	var world: Node2D = get_node_or_null("World") as Node2D
	if world == null:
		return
	AudioManager.play_sfx(&"sd_explosion")
	var effect: SearchDestroyExplosionEffect = SearchDestroyExplosionEffect.new()
	effect.global_position = effect_position
	world.add_child(effect)
	var local_player: PlayerController = player_spawner.get_player(multiplayer.get_unique_id()) as PlayerController
	if local_player:
		local_player.shake_camera(PlayerController.BOMB_SHAKE_STRENGTH * 1.8, PlayerController.BOMB_SHAKE_DURATION * 1.6)


func _sd_update_site_markers() -> void:
	var positions: Array[Vector2] = _get_search_destroy_site_positions()
	for i in range(_sd_marker_nodes.size()):
		var marker := _sd_marker_nodes[i] as SearchDestroySiteMarker
		if marker:
			marker.position = positions[i]
			marker.site_label = SD_SITE_LABELS[i]
			marker.bomb_planted = sd_state == SearchDestroyState.PLANTED or sd_state == SearchDestroyState.DEFUSING
			marker.active = i == sd_active_site_index and _is_search_destroy_mode() and sd_state != SearchDestroyState.MATCH_OVER


func _sd_refresh_hud() -> void:
	var hud := get_node_or_null("CanvasLayer/Root/TopUI/SearchDestroyHud") as Panel
	if hud == null:
		return
	hud.visible = _is_search_destroy_mode() and sd_state != SearchDestroyState.DISABLED and sd_state != SearchDestroyState.MATCH_OVER
	if not hud.visible:
		_sd_refresh_interaction_progress()
		return
	_sd_set_hud_text("ScoreLabel", tr("SD_TEAM_SCORE_FMT") % [int(sd_scores.get(SD_ATTACKER_TEAM, 0)), int(sd_scores.get(SD_DEFENDER_TEAM, 0))])
	_sd_set_hud_text("RoundLabel", tr("SD_ROUND_SITE_FMT") % [sd_round_index, SD_TOTAL_ROUNDS, _sd_site_label()])
	var timer_text: String = tr("SD_BOMB_TIME_FMT") % _format_seconds(sd_bomb_time_left) if sd_state == SearchDestroyState.PLANTED or sd_state == SearchDestroyState.DEFUSING else tr("SD_TIME_FMT") % _format_seconds(sd_round_time_left)
	_sd_set_hud_text("TimerLabel", timer_text)
	_sd_set_hud_text("StatusLabel", _sd_status_text())
	_sd_refresh_interaction_progress()


func _sd_refresh_interaction_progress() -> void:
	var progress := get_node_or_null("CanvasLayer/Root/TopUI/SearchDestroyHud/Box/InteractionProgress") as ProgressBar
	if progress == null:
		return
	var local_peer_id := multiplayer.get_unique_id()
	var is_local_interaction := sd_interacting_peer == local_peer_id
	var duration: float = 0.0
	if sd_interaction_type == "plant":
		duration = SD_PLANT_HOLD
	elif sd_interaction_type == "defuse":
		duration = SD_DEFUSE_HOLD
	var should_show := is_local_interaction and duration > 0.0 and (sd_state == SearchDestroyState.PLANTING or sd_state == SearchDestroyState.DEFUSING)
	progress.visible = should_show
	progress.value = clampf((sd_interaction_progress / duration) * 100.0, 0.0, 100.0) if should_show else 0.0


func _sd_set_hud_text(label_name: String, text: String) -> void:
	var label := get_node_or_null("CanvasLayer/Root/TopUI/SearchDestroyHud/Box/" + label_name) as Label
	if label:
		label.text = text


func _sd_status_text() -> String:
	var role: String = tr("SD_ROLE_PLANT") if _get_local_team() == SD_ATTACKER_TEAM else tr("SD_ROLE_DEFUSE")
	if sd_state == SearchDestroyState.PLANTING:
		return tr("SD_PLANTING_FMT") % clampf((sd_interaction_progress / SD_PLANT_HOLD) * 100.0, 0.0, 100.0)
	if sd_state == SearchDestroyState.DEFUSING:
		return tr("SD_DEFUSING_FMT") % clampf((sd_interaction_progress / SD_DEFUSE_HOLD) * 100.0, 0.0, 100.0)
	if sd_state == SearchDestroyState.PLANTED:
		return tr("SD_BOMB_PLANTED_PLANT") if _get_local_team() == SD_ATTACKER_TEAM else tr("SD_BOMB_PLANTED_DEFUSE")
	return role


func _sd_round_banner_text(winning_team: int, reason: String) -> String:
	var winning_team_name: String = _sd_team_name(winning_team)
	match reason:
		"detonated":
			return tr("SD_BANNER_DETONATED_FMT") % winning_team_name
		"defused":
			return tr("SD_BANNER_DEFUSED_FMT") % winning_team_name
		"timeout":
			return tr("SD_BANNER_TIMEOUT_FMT") % winning_team_name
		"hearts":
			return tr("SD_BANNER_HEARTS_FMT") % winning_team_name
		_:
			return tr("SD_BANNER_WIN_FMT") % winning_team_name


func _sd_team_name(team_id: int) -> String:
	if team_id == SD_ATTACKER_TEAM:
		return tr("SD_TEAM_PLANT")
	if team_id == SD_DEFENDER_TEAM:
		return tr("SD_TEAM_DEFUSE")
	return str(team_id)


func _format_seconds(value: float) -> String:
	var seconds: int = int(ceil(value))
	if seconds < 0:
		seconds = 0
	return "%02d:%02d" % [int(seconds / 60), seconds % 60]


func _sd_site_label() -> String:
	if sd_active_site_index >= 0 and sd_active_site_index < SD_SITE_LABELS.size():
		return SD_SITE_LABELS[sd_active_site_index]
	return str(sd_active_site_index + 1)


func _get_local_team() -> int:
	for item in NetworkManager.current_match_players:
		if not (item is Dictionary):
			continue
		if str(item.get("player_id", "")) == ApiManager.player_id:
			return int(item.get("team_id", 0))
	return SD_ATTACKER_TEAM


func _resolve_team_for_player(player_id: String, match_players: Array, peer_id: int) -> int:
	for item in match_players:
		if not (item is Dictionary):
			continue
		if str(item.get("player_id", "")) == player_id:
			return int(item.get("team_id", 0))
	return SD_ATTACKER_TEAM if peer_to_team.is_empty() or peer_id == 1 else SD_DEFENDER_TEAM


func _get_peer_for_team(team_id: int) -> int:
	for peer_id in peer_to_team:
		if int(peer_to_team[peer_id]) == team_id:
			return peer_id
	return -1


func _get_team_score(team_id: int) -> int:
	if _is_search_destroy_mode():
		return int(sd_scores.get(team_id, 0))
	return 0


func _get_opponent_peer(peer_id: int) -> int:
	for pid in peer_to_player_id:
		if pid != peer_id:
			return pid
	return -1
