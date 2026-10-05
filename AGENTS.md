# AI Agent Context & Reminder

## Project Overview
**Dungeon Crawler 3D** — 3D roguelike dungeon crawler game built in Godot 4.7.2.

**Genre:** Action roguelike, third-person, procedural dungeon generation  
**Target Platform:** Windows (64-bit)  
**Tech Stack:** Godot 4.7.2, GDScript, Jolt Physics, GL Compatibility renderer

---

## Current Status (Last updated: 2026-10-05)

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
- **Player Melee Attack** (`player.gd`): Group-based detection, raycast 2 units forward from facing direction, mouse click triggers, 0.5s cooldown, calls `enemy.die()`
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

### ✅ Completed: Fase 4 — Visual Upgrade & Polish

**New Systems:**
- **Player Model:** Quaternius RPG Warrior (ganti placeholder capsule)
- **Enemy Models:** Quaternius Blob monsters (GreenBlob, Dog, Chicken) — available, currently enemy uses placeholder sphere
- **Combat Polish:** Hit feedback (scale flash), animasi (Idle/Walk/Bite_Front/HitRecieve/Death)
- **Upgrade Visual:** Kenney chest/coin/potion models — ready for swap

**Visual Improvements:**
- Wall height 6x tinggi (player tidak bisa loncat melewati)
- Door frame visual (wall-opening.glb) di celah dinding
- Room lighting (OmniLight3D) per ruangan, energi 2.0, warna hangat
- Projectile Blade Wave: SphereMesh 0.6, scale 1.5x, emission 3.5x, warna biru cyan

**Assets Imported:**
- ✅ Kenney Mini Dungeon (wall-opening.glb untuk frame pintu)

### ✅ Completed: Fase 5 — Player Growth & Progression

**New Systems:**
- **PlayerStats class** (`player_stats.gd`): 16 stat types + logic upgrade
- **UpgradePool** (`upgrade_pool.gd`): 19 upgrade dengan rarity (common/rare/epic)
- **Upgrade Selection UI** (`upgrade_selection.gd`): Tampil saat level up, pilih 1 dari 3
- **Advanced Stats:**
  - lifesteal, crit (chance & damage), regen
  - shield (absorb damage, recharge tiap level)
  - thorns (damage balik ke penyerang)
  - cleave (area damage setelah hit)
  - dash (invuln + speed boost, cooldown)
  - low_hp_damage_boost, kill_speed_boost
  - projectile (Blade Wave, 50% damage dari base)

**Upgrade Types (19 total):**
- Common: max_health, damage, speed, attack_speed, attack_range, heal_now
- Rare: regen, lifesteal, crit_chance, crit_damage, shield, thorns, low_hp_damage, kill_speed, dash_master
- Epic: cleave, projectile

**Flow:**
1. Player naik level → GameManager.next_level() emit `level_completed`
2. UpgradeSelection UI muncul (CanvasLayer 101, di atas fade overlay layer 99)
3. Player pilih 1 dari 3 upgrade random
4. GameManager.apply_upgrade() → apply ke PlayerStats
5. Dungeon regenerate → player lanjut ke level baru

### ✅ Completed: Fase 6 — Polish & Inspector Config (2026-10-05)

**New Systems:**
- **Dungeon Visual Config:** Semua parameter dinding/pintu/column/lighting bisa diedit dari Godot Inspector tanpa edit kode
- **Transition Fix:** Fade black sebelum upgrade UI muncul (await upgrade_applied signal)
- **Project Visual:** Blade Wave sphere mesh + bright emission + transparency
- **Lighting:** OmniLight3D per ruangan, ambient + directional light tuning
- **Wall Height:** 6x (bisa di-tweak di Inspector)

**Inspector Parameters (DungeonManager node):**
```
Wall: wall_height (6.0), wall_scale_xz (1.0), wall_collision_height (6.6), wall_collision_thickness (0.3)
Door: door_height (6.0), door_scale_xz (1.0)
Column: column_height (6.0)
Lighting: room_light_height (4.0), room_light_range (18.0), room_light_energy (2.0), room_light_color, room_light_attenuation, room_light_shadow (false)
Props: props_min_count (0), props_max_count (3)
```

**Fixes:**
- UpgradeSelection UI tidak terlihat karena layer 101 di atas fade layer 99
- Wall scale & collision box tidak sinkron (sekarang 6x)
- Door frame tidak ada visual (sekarang pakai wall-opening.glb)
- No lighting di dalam dungeon (sekarang ada OmniLight3D per ruangan)

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

## Known Issues & Limitations

✅ **Verified Working:**
- Dungeon generation (tested headless: "Generated level 1: 3 rooms, size 10")
- Floor collision (player no longer falls through)
- Exit door glow + visual marker
- Fade transition smooth
- Upgrade UI visible during transition (layer fix)
- Wall height 6x (cannot jump over)
- Room lighting (OmniLight3D per room)
- Projectile visible (SphereMesh + emission)
- Inspector-configurable dungeon visuals

⚠️ **Not Verified Visually (may need tuning):**
- Wall rotation accuracy (0/90/180/270° — visual check needed in editor)
- Door gap alignment with trigger box (width 2 tiles, may need offset adjustment)
- Props spawn position (may clip walls if unlucky RNG)

❌ **Not Yet Implemented:**
- **Audio** (no SFX/music)
- **Minimap** (would be useful for dungeon exploration)
- **Multiple enemy types/tiers** (all enemies identical currently)
- **Boss fights**
- **Particles/VFX** (hit sparks, crit effect, death explosion, screen shake)
- **Persistence** (save/load progress, high score)

---

## Next Steps (Fase 7 — Content & Polish)

**Plan:**
1. **Audio:** Sound manager + SFX (footsteps, hits, pickup, level up) + BGM
2. **Enemy Variety:** Multiple tiers (Blob/Big/Flying), ranged enemies, elite variants
3. **Boss Fights:** Boss room, unique mechanics, special rewards
4. **Minimap:** Dungeon navigation UI
5. **VFX:** Particles (hit sparks, crit effect, death explosion), screen shake
6. **Balancing:** Enemy HP/damage curve, upgrade value tuning
7. **Persistence:** Save/load progress, high score

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
7. **GDScript type inference with `get_nodes_in_group()`** → returns untyped Array, elements are `Variant`. Accessing `.global_position` etc. produces `Variant`, so `var x := enemy.position.length()` fails to infer. **Fix:** use explicit types (`var dist: float = ...`) or cast (`var e := enemy as Node3D`).
8. **Attack input bug (fixed):** Original thin raycast (2 units) was too short and required exact facing. Now uses group-based detection (`enemies` group) with 3-unit range + camera-direction aim + 0.5s cooldown. Input: left mouse click OR F key.
9. **Unicode em-dash in comments** → can cause parse errors. Keep comments ASCII-only.

---

## Attack System (Fase 3)

- **Input:** Left mouse click OR `F` key
- **Range:** 3 units, cooldown 0.5s
- **Direction:** Player auto-faces camera forward direction
- **Detection:** All enemies in `enemies` group within range, in front (dot > 0.3)
- **Effect:** `enemy.die()` → drops upgrade pickup

---

## Contact / Continuation

If resuming this project in future session:
1. Read `DEVELOPMENT_LOG.md` for human-readable history
2. Check `git log --oneline -10` for recent changes
3. Run game in editor (F5) to verify current state
4. Ask user: "Mau lanjut ke Fase 3 (enemies + combat) atau ada yang perlu diperbaiki dari Fase 2?"
