# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Knockback is a mobile-first 2D multiplayer game built with **Godot 4.6** using GDScript 2.0. It targets Android (APK) and Windows Desktop. The game uses ENet peer-to-peer multiplayer with a max of 2 players per match.

## Running the Project

- Open with **Godot 4.6.1-stable** (editor)
- Main scene: `scenes/main.tscn`
- Server mode: run with `--dedicated_server` feature flag
- Client mode: default when running normally
- Multiplayer connects to `127.0.0.1:9543`

## Export Targets

- **Windows**: `export/knockback.exe` (x86_64)
- **Android**: APK with Gradle build, ARM64-v8a only, package `com.example.knockback`

Android build requires Gradle 8.11.1 and the Google Sign-In dependencies (Credential Manager API).

## Architecture

### Autoloads (Singletons)

- **NetworkManager** (`scripts/global_scripts/network_manager.gd`) — Creates ENet server/client, handles peer connect/disconnect events, triggers game scene loading
- **SceneLoader** (`scripts/global_scripts/scene_loader.gd`) — Threaded async scene loading with progress tracking; instantiates scenes into `Main/SceneContainer`

### Scene Hierarchy

```
Main (Node2D)
├── SceneContainer — Dynamic scene container (scenes loaded here by SceneLoader)
├── GlobalUI (CanvasLayer) — Loading screen with progress bar
└── TransitionLayer (CanvasLayer) — Fade in/out animations for scene changes
```

### Key Scene Flows

1. **Login** → Google Sign-In (Android) or skip → loads lobby
2. **Lobby** → Overlay-based UI (shop, equipment, leaderboard, wheel, etc.) managed by `LobbyUIManager`
3. **Game** → `PlayerSpawner` waits for 2 peers, spawns `CharacterBody2D` players at random positions; movement via virtual joystick; position synced via `MultiplayerSynchronizer`

### Multiplayer Model

- `PlayerSpawner` (extends `MultiplayerSpawner`) spawns players when 2 peers connect
- Player input only processed by the multiplayer authority owner
- Position replication is server-authoritative (replication mode 2)

### Plugins

- **virtual_joystick_plus** (`addons/virtual_joystick_plus/`) — Touch joystick with NORMAL/DYNAMIC/FOLLOW modes
- **google_sign_in** (`addons/google_sign_in/`) — Android Credential Manager API integration; returns `id_token`, `email`, `display_name`

## Code Conventions

- GDScript 2.0 syntax: `@export`, `@onready`, `class_name`, typed variables
- Unique node references via `%NodeName` pattern
- Scripts live in `scripts/` mirroring the `scenes/` directory structure
- Signals for inter-node communication
- Viewport: 1080×486 (mobile landscape aspect ratio)
- Renderer: Mobile with ETC2/ASTC texture compression
