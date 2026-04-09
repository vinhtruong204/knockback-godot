# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Knockback** is a networked multiplayer 2D action game built with **Godot 4.6** (Mobile renderer). Players engage in PvP combat with physics-based knockback mechanics. The game has a REST API backend, Google Sign-In auth, and progression systems (shop, equipment, economy, ranks).

Target platforms: Android (primary) and Windows (dedicated server).

**Display:** 1080x486 viewport, `canvas_items` stretch mode, `expand` aspect, VSync off, mouse-to-touch emulation enabled for desktop testing.

## Running the Project

- Open in Godot 4.6 editor and run (F5), or use CLI: `godot --path .`
- Dedicated server: `godot --path . --dedicated_server` (exports with `export/knockback.exe`)
- Android build: Export via editor or `godot --export-release "Android" export/knockback.apk`
- Windows server export: `godot --export-release "Windows Desktop" export/knockback.exe`

There are no separate build, lint, or test commands — this is a Godot project managed through the editor and engine CLI.

## Architecture

### Autoload Singletons (global managers, always available)

| Singleton | Script | Role |
|-----------|--------|------|
| SceneLoader | `scripts/global_scripts/scene_loader.gd` | Threaded scene loading with progress tracking |
| NetworkManager | `scripts/global_scripts/network_manager.gd` | ENet multiplayer peer setup (server/client) |
| ApiManager | `scripts/global_scripts/api_network/api_services/api_manager.gd` | Base HTTP client, session token, auth headers |
| PlayerApi | `scripts/global_scripts/api_network/api_services/player_api.gd` | Auth, profiles, inventory, equipment, currency |
| ConfigApi | `scripts/global_scripts/api_network/api_services/config_api.gd` | Weapons, characters, achievements, level/rank configs |
| EconomyApi | `scripts/global_scripts/api_network/api_services/economy_api.gd` | Shop items, currency |
| MatchApi | `scripts/global_scripts/api_network/api_services/match_api.gd` | Matches, matchmaking, maps, modes |
| CacheManager | `scripts/global_scripts/api_network/api_services/cache_manager.gd` | Multi-tier caching (static 1h, semi 5m, dynamic 30s) with disk persistence |
| AudioManager | `scripts/global_scripts/audio/audio_manager.gd` | Audio bus volume control (Music, SFX) |

### Scene Flow

```
Main (main.tscn)
├── SceneContainer  ← SceneLoader swaps scenes here
├── GlobalUi        ← Persistent loading screen, notifications, confirmations
└── TransitionLayer ← Fade in/out animations between scenes

Flow: Login → Lobby → Game
- Dedicated server: OS.has_feature("dedicated_server") → skips login/lobby, loads game directly
- Client: Login (Google/dev) → Lobby (UI panels) → Game (on match start)
```

### Backend API (REST, 4 microservices)

Base URL: `http://100.96.156.107`

| Port | Service | Endpoints |
|------|---------|-----------|
| 8000 | Player | `/auth/*`, `/players/*`, `/player-inventory/*`, `/player-equipment/*`, `/player-currency/*` |
| 8001 | Config | `/weapons`, `/characters`, `/achievements`, `/level-configs`, `/rank-configs` |
| 8002 | Economy | `/shops/*` |
| 8003 | Match | `/matches/*`, `/match-players/*`, `/matchmaking/*`, `/maps`, `/modes` |

Auth: Bearer token via `Authorization` header. Session stored at `user://auth.cfg`.

### API Callback & Caching Pattern

All API calls follow the same callback pattern with a standard response shape:

```gdscript
# Calling an API method:
PlayerApi.get_player_profile(player_id, func(response):
    if response.get("ok", false):
        var data = response["data"]  # parsed model or dict
    else:
        var error = response.get("error", "Unknown error")
)

# Response format: {ok: bool, status: int, data: Variant, error: String}
```

API services use CacheManager with `fetch_or_cache()` before making HTTP requests:

```gdscript
func get_resource(id, callback, force_refresh := false):
    var key := "category:resource:" + str(id)
    if force_refresh:
        CacheManager.invalidate(key)
    CacheManager.fetch_or_cache(key, TTL, "category", persist_flag,
        func(cb): ApiManager.send_request(...),
        callback)
```

Cache TTL tiers and invalidation:

| Category | TTL | Use Case | Persist to disk |
|----------|-----|----------|-----------------|
| config | 3600s | Weapons, characters, maps, modes | Yes |
| match_config | 3600s | Maps, modes | Yes |
| economy | 300s | Shop items | No |
| player | 300s | Profile, stats, achievements | No |
| player_dynamic | 30s | Currency, inventory, equipment | No |

After any write operation (purchase, equip, currency change), invalidate relevant cache:
- `CacheManager.invalidate("player:profile:" + pid)` — single key
- `CacheManager.invalidate_category("player_dynamic")` — all keys in category
- `CacheManager.invalidate_player(pid)` — all keys containing player ID

### GlobalUI System

GlobalUI is persistent across scenes. Access from any script via:
```gdscript
get_tree().root.get_node("Main/GlobalUi")
```

Three subsystems:
- **LoadingContainer** — `show_loading_screen()`, auto-polls `SceneLoader.get_progress()`, auto-hides at 100%
- **NotificationPanel** — `show_purchase_notification()`, `show_reward_notification()`, `show_error_notification()`
- **ConfirmationContainer** — `show_confirm_purchase(item_type, price, currency_type, on_confirm: Callable)`

### Multiplayer Networking

- **Protocol:** ENetMultiplayerPeer (UDP), server at `100.96.156.107:9543`
- **Authority model:** Server is authority. Clients send RPC requests, server validates and executes.
- **Spawners:** `MultiplayerSpawner` nodes for players, bullets, bombs, maps — server-side only.
- **Max players:** 2 per match

**RPC patterns used throughout the codebase:**

```gdscript
# Client → server (1 = server peer ID):
func_name.rpc_id(1, args)

# Server → all clients:
@rpc("authority", "call_remote", "reliable")
func do_something(): ...

# Any peer → server with authority check:
@rpc("any_peer", "call_remote", "reliable")
func take_damage_rpc(damage: int):
    if not multiplayer.is_server(): return
    # server-side logic

# Authority guards:
if not is_multiplayer_authority(): return  # only local player processes input
if not multiplayer.is_server(): return     # only server processes game logic
```

### Match Lifecycle

The match flow spans `game_manager.gd` → `match_result_panel.gd` → API services:

1. **Pre-match:** Matchmaking sets `NetworkManager.current_match_id`, `.current_match_players`, `.current_map_name`, `.current_player_name` before connecting to the game server.
2. **Registration:** Client calls `register_player.rpc_id(1, player_id, match_id, name, map_name)`. Server tracks peers in `peer_to_player_id` / `peer_to_name` dicts. Once both registered, server broadcasts names to clients for UI.
3. **Match end:** Triggered by `player_eliminated` signal (hearts=0) or client disconnect (forfeit). `GameManager._end_match()` broadcasts `_receive_match_result.rpc()` with per-player stats and rewards.
4. **Post-match (client):** `MatchResultPanel` shows stats with 5s auto-confirm countdown, then executes sequential API calls: add gold → update match-player record → add exp → update cumulative stats → update rank → invalidate caches → `NetworkManager.leave_game()` → lobby.
5. **Server cleanup:** 10s after broadcasting results, server resets state and reloads game scene via `SceneLoader`.

**Reward constants** (in `GameManager`):

| Result | Gold | EXP | Rank Points |
|--------|------|-----|-------------|
| Win | 50 | 100 | +15 |
| Lose | 20 | 50 | -10 |
| Forfeit | 0 | 0 | -20 |

Key files: `scripts/main_container/game/game_manager.gd`, `scripts/main_container/game/ui/match_result/match_result_panel.gd`

### Player System (component-based)

Scripts in `scripts/main_container/game/player/`. Components communicate via signals.

| Component | Responsibility | Key Signals |
|-----------|---------------|-------------|
| `player_controller.gd` | CharacterBody2D root, camera, death/respawn | — |
| `player_input.gd` | Reads joystick/keyboard (authority only) | `jump`, `drop_down`, `shoot`, `throw_bomb`, `switch_weapon` |
| `player_movement.gd` | Gravity, velocity, knockback blending, platform drop-through | Listens to `jump`, `drop_down` |
| `player_health.gd` | HP (100) + hearts (3), damage RPC, death on 0 hearts | `health_changed`, `heart_changed`, `oponent_heart_changed` |
| `player_knockback.gd` | Applies knockback/bomb force vectors via RPC | — |
| `player_flip.gd` | Sprite direction (LEFT/RIGHT) based on input | — |
| `player_attack.gd` | Shoot RPC → server spawns bullet via BulletSpawner | Listens to `shoot` |
| `player_throw_bomb.gd` | Throw bomb RPC → server spawns bomb | Listens to `throw_bomb` |
| `weapon_hold_handler.gd` | Manages 3 weapon nodes (PRIMARY, SECONDARY, MELEE), swaps on `weapon_switched` signal | — |

**Projectile values** (affect game balance):
- **Bullet:** 200 px/s speed, 4s lifetime, 50 damage, owner-excluded
- **Bomb:** 3s fuse, 30 damage + dir*150 knockback force, owner-excluded

### Physics Collision Layers

1. Player  2. Map  3. Bullet  4. Grenade  5. Explode Zone  6. Death Zone

### Input Mappings

- `player_jump` → Space
- `player_attack` → Right Arrow
- `player_throw_bomb` → E
- Mobile: VirtualJoystickPlus addon for movement (`get_value() → Vector2`), on-screen buttons for actions

### Data Models & Enums

Defined in `scripts/global_scripts/api_network/models/`:
- `enums.gd`: ItemType, CurrencyType, MatchStatus, MatchResult, GameMode, SlotType
- `player_models.gd`, `match_models.gd`, etc.: API response models with `from_dict()`/`from_array()`/`to_dict()`

### Lobby UI

`scripts/main_container/lobby/` manages overlay panels: shop, equipment, normal matchmaking, LAN, leaderboard, rank, profile, tasks, wheel. Each panel is a separate scene loaded into the lobby overlay. Panel visibility is toggled via `_open_[panel_name]()` methods in `lobby_ui_manager.gd`.

### Login & Auth Flow

- **Android:** Google Sign-In plugin → `id_token` → `PlayerApi.login(id_token, callback)` → save session
- **Non-Android (dev):** `PlayerApi.dev_login("DevPlayer", "", callback)` → same flow
- **Session check:** `ApiManager.is_logged_in()` on startup; if true, skip login and go to lobby
- **Sign out:** `PlayerApi.signout()` → clear ApiManager session → `CacheManager` clear all → reload login scene

### Key Conventions

- GDScript with `class_name` declarations on model/enum files
- Signals for intra-component communication within player system
- `is_multiplayer_authority()` guard on input processing (only local player processes input)
- API services return parsed model objects; cache is checked before HTTP requests
- Scene paths referenced by `res://` paths in script constants
- Addons: `google_sign_in` (Android auth), `virtual_joystick_plus` (mobile input)
