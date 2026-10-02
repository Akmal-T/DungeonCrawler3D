# AI Agent Context & Reminder

## Project Overview
**Dungeon Crawler 3D** — 3D roguelike dungeon crawler game built in Godot 4.7.2.

**Genre:** Action roguelike, third-person, procedural dungeon generation  
**Target Platform:** Windows (64-bit)  
**Tech Stack:** Godot 4.7.2, GDScript, Jolt Physics, GL Compatibility renderer

---

## Current Status (Last updated: 2026-10-03)

### ✅ Completed: Fase 2 — Dungeon Room System (MVP)

**Core Systems Working:**
- **Player:** Third-person orbit camera (Zelda-style), WASD movement, jump, gravity, placeholder capsule mesh
- **Dungeon Generation:** Grid-based random walk (3x3 max), procedural room layout per level, difficulty scaling (room count + size)
- **Room Building:** Kenney Mini Dungeon tiles (floor, wall, column, props), programmatic generation via `room_builder.gd`
- **Door System:** Normal doors (explore between rooms) + Exit door (1 per dungeon, red glow + gate.glb, triggers level transition with fade)
- **Level Transition:** Fade black → next level → regenerate dungeon → fade in
- **UI:** HUD (level, score, HP bar), Game Over screen (restart button)
- **Game Loop:** Die → Game Over → Restart to Level 1

### ✅ Completed: Fase 3 — Enemies & Combat

**New Systems:**
- **Enemy AI** (`enemy.gd`): CharacterBody3D, chase player within detection_range (15), contact damage
- **Enemy Spawning:** Spawn in non-start/non-exit rooms, count = `1 + (level-1)/2`, speed/damage scale with level
- **Player Melee Attack** (`player.gd`): Raycast 2 units forward from facing direction, mouse click triggers, 0.5s cooldown, calls `enemy.die()`
- **Upgrade Pickups** (`upgrade_pickup.gd`): 4 types — health_potion (heal 20), speed_boost (+0.1x), damage_boost (+5), max_health (+20)
- **Enemy Drops:** On death, spawn upgrade pickup at enemy position
- **Player Group:** Player tagged in "player" group for enemy targeting
- **Enemy Visual:** Red emissive sphere (placeholder, replace with Quaternius Blob later)

**Combat Loop:**
1. Enemy detects player within 15 units → chases
2. Within 1.5 units → attacks (damage = 10 + level*2, 0.5s delay)
3. Player clicks mouse → raycast hits enemy → enemy dies → drops pickup
4. Player walks over pickup → applies buff

**Assets Imported:**
- ✅ Kenney Mini Dungeon (30 GLB models: wall, floor, gate, column, barrel, pot, chest, etc.)
- ✅ Quaternius Ultimate Monsters (54 GLTF: Blob/Big/Flying categories) — **available, currently enemy uses placeholder sphere**
- ✅ Quaternius RPG Characters (6 GLTF: Warrior, Ranger, Wizard, etc.) — **ready for player upgrade**

---

## File Structure (Important)

```
D:\GAME\BuildingAGame\
├── Assets/
│   ├── Kenney_MiniDungeon/Models/GLB format/   ← 30 tiles (wall, floor, gate, column, props)
│   ├── Quaternius_Monsters/.../glTF/           ← 54 monsters (Blob, Big, Flying)
│   └── Quaternius_RPG/.../glTF/                ← 6 RPG characters
│
├── Scenes/
│   ├── Dungeon/
│   │   ├── dungeon_manager.gd    ← Grid generation, room spawning, level transition, enemy spawning
│   │   ├── door.gd / door.tscn   ← Area3D trigger (normal vs exit)
│   │   ├── world.gd / world.tscn ← Root scene (main_scene)
│   │
│   ├── Player/
│   │   ├── player.gd / player.tscn         ← CharacterBody3D (placeholder capsule) + melee attack
│   │   └── camera_orbit.gd                 ← Third-person orbit camera
│   │
│   ├── Enemies/
│   │   └── enemy.gd / enemy.tscn           ← CharacterBody3D, chase AI, contact damage
│   │
│   ├── Upgrades/
│   │   └── upgrade_pickup.gd / upgrade_pickup.tscn  ← Area3D pickups (4 buff types)
│   │
│   └── UI/
│       ├── hud.gd / hud.tscn               ← Level, Score, HP
│       └── game_over.gd / game_over.tscn   ← Restart screen
│
├── Scripts/
│   ├── game_manager.gd     ← Singleton (autoload): HP, level, score, signals
│   └── room_builder.gd     ← Static class: build room from tiles programmatically
│
└── Materials/
    ├── floor_mat.tres, wall_mat.tres, player_mat.tres
```

---

## Key Design Decisions & Technical Notes

### Dungeon Generation Logic (`dungeon_manager.gd`)
- **Grid:** 3x3 max, random walk from center
- **Room count:** `3 + (level - 1)`, max 9
- **Room size:** `10 + (level - 1) * 2` tiles, max 16
- **Spacing:** `room_size` units (rooms touch edge-to-edge)
- **Exit room:** Farthest room from start (Manhattan distance)
- **Seed:** `hash("dungeon_level_%d" % level)` for reproducibility

### Room Building (`room_builder.gd`)
- **Floor:** Checkerboard `floor.glb` / `floor-detail.glb`, 1 StaticBody3D collision box per room
- **Walls:** `wall.glb` + StaticBody3D per tile, rotation per side (0/90/180/270°), skip tiles with doors
- **Columns:** 4 corners per room (`column.glb`)
- **Props:** Random 0-3 props (barrel, pot, rocks, stones)
- **Door width:** 2 tiles (`DOOR_WIDTH = 2`)

### Door System
- **Normal doors:** Celah di dinding, no trigger (explore freely)
- **Exit door:** Only 1 per dungeon, red OmniLight3D + gate.glb mesh, triggers `_transition_to_next_level()`

### Player Movement
- **WASD:** Relative to camera basis (forward = -camera_z projected to XZ plane)
- **Jump:** Space, `jump_velocity = 5.5`
- **Speed multiplier:** `GameManager.player_speed_multiplier` (ready for upgrades)
- **Fall detection:** y < -20 → kill player

### Camera (`camera_orbit.gd`)
- **Mouse look:** Captured mouse, yaw/pitch rotation
- **Zoom:** Scroll wheel, range 2-8 units
- **ESC:** Toggle mouse capture (debug)

---

## Known Issues & Limitations (Fase 2)

✅ **Verified Working:**
- Dungeon generation (tested headless: "Generated level 1: 3 rooms, size 10")
- Floor collision (player no longer falls through)
- Exit door glow + visual marker
- Fade transition smooth

⚠️ **Not Verified Visually (may need tuning):**
- Wall rotation accuracy (0/90/180/270° — visual check needed in editor)
- Door gap alignment with trigger box (width 2 tiles, may need offset adjustment)
- Props spawn position (may clip walls if unlucky RNG)

❌ **Not Yet Implemented:**
- **Visual models** (enemies = placeholder sphere, player = placeholder capsule — real models ready)
- **Audio** (no SFX/music)
- **Minimap** (would be useful for dungeon exploration)
- **Enemy health** (currently die in 1 hit — no HP bar)
- **Multiple enemy types/tiers** (all enemies identical currently)

---

## Next Steps (Fase 3 — Enemies & Combat) — ✅ COMPLETED

**Plan:**
1. **Enemy AI:**
   - Use Quaternius Blob monsters (GreenBlob, Dog, Chicken) as tier 1
   - Simple chase AI (NavMesh or direct pathfinding)
   - Spawn enemies in rooms (not start room, not exit room)
   - Die → drop upgrade pickup

2. **Combat System:**
   - Player melee attack (short-range raycast or Area3D hitbox)
   - Enemy contact damage (on collision with player)
   - Health system (already in GameManager, connect to damage)
   - Hit feedback (screen shake, particle, sound)

3. **Upgrade Drops:**
   - Use Kenney chest/coin/potion models
   - Buff types: speed+, damage+, HP+, max HP+
   - Pickup Area3D → apply buff → destroy

4. **Difficulty Scaling:**
   - Enemy count per room: `1 + level / 2`
   - Enemy HP/damage scaling: `base * (1 + level * 0.2)`

---

## Next Steps (Fase 4 — Polish & Visual Upgrade)

**Plan:**
1. **Player Model:** Replace placeholder capsule dengan Quaternius RPG (Warrior/Wizard)
2. **Enemy Models:** Replace red sphere dengan Quaternius Blob (GreenBlob, Dog, Chicken)
3. **Combat Polish:** Add hit feedback (screen shake, particles), sound SFX
4. **Pickups:** Replace sphere dengan Kenney chest/coin/potion models
5. **Audio:** Sound manager + SFX for footsteps, hits, pickup

---

## Commands for Future Sessions

### Run Game (headless test)
```powershell
$exe = "C:\Users\ASUS\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
& $exe --headless --path "D:\GAME\BuildingAGame" --quit-after 30
```

### Open in Editor
```powershell
& "C:\Users\ASUS\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --path "D:\GAME\BuildingAGame"
```

### Check Script Syntax (note: --check-only doesn't load autoload, so errors on GameManager reference are false positives)
```powershell
& $exe --headless --path "D:\GAME\BuildingAGame" --check-only --script "res://Scripts/room_builder.gd"
```

### Git Status
```powershell
cd "D:\GAME\BuildingAGame"
git status
```

---

## Code Conventions

- **GDScript style:** snake_case functions, _private_vars, type hints (`: Type`), explicit `static` for RoomBuilder
- **No comments in code** unless absolutely necessary (self-documenting names preferred)
- **Signal naming:** past tense (`player_died`, `level_completed`)
- **Scene naming:** snake_case filenames, PascalCase node names
- **Export vars:** Use `@export` for tweakable values (speed, jump, etc.)
- **Singleton access:** `GameManager.variable` (direct access, no `get_node()`)

---

## User Preferences (from session history)

- **Language:** Indonesian (untuk komunikasi) + English (untuk code/comments)
- **Approach:** Belajar sambil bikin — user punya pengalaman Godot dasar (Pong/Snake), naik ke 3D pertama kali
- **Design preference:** Low-poly placeholder dulu, upgrade visual nanti (pragmatic iterative development)
- **Scope management:** MVP dulu (core gameplay loop solid), polish & features nanti

---

## Important Gotchas

1. **Godot 4.7 `--check-only` doesn't load autoload** → GameManager undefined error is false positive when using `--check-only`. Use headless run instead for validation.
2. **`.godot/` must be gitignored** → large cache, don't commit
3. **GLB import requires editor open once** → run `--editor --quit` after adding new assets to trigger import
4. **Type inference strict in GDScript** → use explicit `: Type` if inference fails (e.g., `var is_door: bool = ...`)
5. **StaticBody3D required for collision** → mesh alone doesn't collide with CharacterBody3D
6. **Area3D uses BoxShape3D directly** (not ConcavePolygonShape) for triggers

---

## Contact / Continuation

If resuming this project in future session:
1. Read `DEVELOPMENT_LOG.md` for human-readable history
2. Check `git log --oneline -10` for recent changes
3. Run game in editor (F5) to verify current state
4. Ask user: "Mau lanjut ke Fase 3 (enemies + combat) atau ada yang perlu diperbaiki dari Fase 2?"
