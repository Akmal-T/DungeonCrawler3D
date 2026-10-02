# Development Log

## 2026-10-03 — Fase 3: Enemies & Combat

### Summary
Implemented enemy AI, player melee combat, dan upgrade drop system.

### What Works
✅ Enemy AI: chase player (detection 15 units), contact damage (10 + level*2)  
✅ Enemy spawning: non-start/non-exit rooms, count = 1 + (level-1)/2  
✅ Player melee attack: raycast 2 units, mouse click, 0.5s cooldown  
✅ Enemy death drops upgrade pickup  
✅ 4 upgrade types: health_potion, speed_boost, damage_boost, max_health  
✅ Player in "player" group for enemy targeting  

### Known Issues
⚠️ Enemy uses placeholder red sphere (Quaternius Blob models ready to swap)  
⚠️ Enemy dies in 1 hit (no HP system yet)  
⚠️ No hit feedback (screen shake/particles) yet  

### Files Created
```
Scenes/Enemies/enemy.gd / enemy.tscn           (chase AI + contact damage)
Scenes/Upgrades/upgrade_pickup.gd / .tscn      (4 buff types)
Scenes/Player/player.gd                        (updated: melee attack)
Scenes/Dungeon/dungeon_manager.gd              (updated: enemy spawning)
```

### Git
- Commit: `c2a6e2e` Fase 3: Enemies & Combat system
- Pushed to origin/main

---

## 2026-10-03 — Fase 2: Dungeon Room System (MVP)

### Summary
Successfully implemented 3D roguelike dungeon crawler MVP dengan:
- Procedural room generation (grid-based random walk)
- Player movement (WASD + jump + gravity) dengan third-person camera orbit
- Door system: normal doors (explore) + exit door (next level + fade transition)
- UI: HUD (level, score, HP) + Game Over screen
- Asset: Kenney Mini Dungeon (30 GLB), Quaternius Monsters/RPG (ready for Fase 3)

### What Works
✅ Dungeon generated: 3 rooms, size 10 for level 1  
✅ Floor collision ( StaticBody3D per room)  
✅ Player can walk/jump/rotate camera  
✅ Exit door (red glow + gate.glb) triggers level transition  
✅ Fade effect smooth  
✅ HUD update via GameManager signals  

### Known Issues
⚠️ Wall rotation visual — 0/90/180/270° needs editor verification  
⚠️ Door gap alignment — lebar 2 tiles, mungkin perlu offset tuning  
⚠️ Props spawn — random 0-3, mungkin clip walls  

### Tech Notes
- Godot 4.7.2, GDScript, Jolt Physics, GL Compatibility renderer  
- All assets GLB/GLTF, FBX/OBJ/Blend cleaned up  
- Room building via `room_builder.gd` (programmatic tile placement)  
- Dungeon layout via `dungeon_manager.gd` (grid random-walk, spawn rooms)  

### Files Created
```
Assets/Kenney_MiniDungeon/Models/GLB format/  (30 models)
Assets/Quaternius_Monsters/.../glTF/          (54 monsters)
Assets/Quaternius_RPG/.../glTF/               (6 characters)

Scripts/game_manager.gd    (singleton: HP, level, score)
Scripts/room_builder.gd    (static: build room from tiles)
Scenes/Dungeon/dungeon_manager.gd  (grid gen + level transition)
Scenes/Dungeon/door.gd/tscn        (Area3D trigger)
Scenes/Dungeon/world.gd/tscn       (root scene)
Scenes/Player/player.gd/tscn       (CharacterBody3D)
Scenes/Player/camera_orbit.gd      (orbit camera)
Scenes/UI/hud.gd/tscn              (level, score, HP)
Scenes/UI/game_over.gd/tscn        (restart screen)
```

### Commands (from AGENTS.md)
```powershell
# Run headless
& "C:\Users\ASUS\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --headless --path "D:\GAME\BuildingAGame" --quit-after 30

# Editor
& "C:\Users\ASUS\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --path "D:\GAME\BuildingAGame"

# Git
git status
```

### Next (Fase 4)
- Player model: Quaternius RPG characters
- Enemy models: Quaternius Blob monsters
- Combat polish: hit feedback, particles
- Audio: SFX + music
- Enemy health system (multi-hit)

### Git
- Repo: `DungeonCrawler3D` (public)
- Commit: Initial commit Fase 2 MVP
