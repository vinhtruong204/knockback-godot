# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Knockback** is a networked multiplayer 2D action game built with **Godot 4.6** (Mobile renderer). Players engage in PvP combat with physics-based knockback mechanics. The game has a REST API backend, Google Sign-In auth, and progression systems (shop, equipment, economy, ranks).

Target platforms: Android (primary) and Windows (dedicated server).

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
| SceneLoader | `scripts/global_scripts/scene_loader.gd` | Threaded scene loading with transitions |
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
├── GlobalUi        ← Persistent loading screen, transitions
└── TransitionLayer

Flow: Login → Lobby → Game
- Dedicated server skips login/lobby, loads game scene directly
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

### Multiplayer Networking

- **Protocol:** ENetMultiplayerPeer (UDP), server at `100.96.156.107:9543`
- **Authority model:** Server is authority. Clients send RPC requests, server validates and executes.
- **Spawners:** `MultiplayerSpawner` nodes for players, bullets, bombs, maps — server-side only.
- **RPC pattern:**
  - Client → server: `func_name.rpc_id(1, args)` (1 = server peer ID)
  - Server → clients: `@rpc("authority", "call_remote", "reliable")`
  - Damage: `@rpc("any_peer", "call_remote", "reliable")` with authority check
- **Max players:** 2 per match

### Player System (component-based)

Scripts in `scripts/main_container/game/player/`:

| Component | Responsibility |
|-----------|---------------|
| `player_controller.gd` | CharacterBody2D root, camera setup, death/respawn |
| `player_input.gd` | Reads joystick/keyboard, emits jump/shoot/throw_bomb signals |
| `player_movement.gd` | Gravity, velocity, knockback blending, platform drop-through |
| `player_health.gd` | HP (100) + hearts (3), damage RPC, death on 0 hearts |
| `player_knockback.gd` | Applies knockback/bomb force vectors via RPC |
| `player_flip.gd` | Sprite direction (LEFT/RIGHT) based on input |
| `player_attack.gd` | Shoot RPC → server spawns bullet |
| `player_throw_bomb.gd` | Throw bomb RPC → server spawns bomb |

### Physics Collision Layers

1. Player  2. Map  3. Bullet  4. Grenade  5. Explode Zone  6. Death Zone

### Input Mappings

- `player_jump` → Space
- `player_attack` → Right Arrow
- `player_throw_bomb` → E
- Mobile: VirtualJoystickPlus plugin for movement, on-screen buttons for actions

### Data Models & Enums

Defined in `scripts/global_scripts/api_network/models/`:
- `enums.gd`: ItemType, CurrencyType, MatchStatus, MatchResult, GameMode, SlotType
- `player_models.gd`, `match_models.gd`, etc.: API response models with `from_dict()`/`to_dict()`

### Lobby UI

`scripts/main_container/lobby/` manages overlay panels: shop, equipment, normal matchmaking, LAN, leaderboard, rank, profile, tasks, wheel. Each panel is a separate scene loaded into the lobby overlay.

### Key Conventions

- GDScript with `class_name` declarations on model/enum files
- Signals for intra-component communication within player system
- `is_multiplayer_authority()` guard on input processing (only local player processes input)
- API services return parsed model objects; cache is checked before HTTP requests
- Scene paths referenced by `res://` paths in script constants
