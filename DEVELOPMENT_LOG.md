# Development Log

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

### Next (Fase 3)
- Enemies: Quaternius Blob monsters (GreenBlob, Dog, Chicken)
- Combat: melee attack, contact damage
- Upgrades: chest/coin/potion drops
- Player model: Quaternius RPG characters

### Git
- Repo: `DungeonCrawler3D` (public)
- Commit: Initial commit Fase 2 MVP
