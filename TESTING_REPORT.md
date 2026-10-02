# Testing Report — Dungeon Crawler 3D

**Tanggal:** Testing otomatis Fase 4
**Metode:** Integration test headless (Godot 4.7.2)
**Total test:** 56 — **56 passed, 0 failed**

---

## Ringkasan Test

| Suite | Test | Hasil |
|-------|------|-------|
| `test_runner.tscn` | 20 | ✅ ALL PASS |
| `test_advanced.tscn` | 26 | ✅ ALL PASS |
| `test_door.tscn` | 10 | ✅ ALL PASS |

---

## Coverage

### test_runner.tscn — Core Logic (20 test)
- Scene load (world, player, dungeon manager)
- GameManager init (level=1, HP=100, score=0)
- Dungeon generation (>= 3 rooms)
- Player structure (group, MeshRoot, Warrior model)
- Enemy spawn + struktur
- Combat: damage, kill, score increase
- Pickup: damage & heal
- Level transition: increment level, score
- Game over: HP=0, signal emitted

### test_advanced.tscn — Physics & Systems (26 test)
- Scene structure (environment, lighting, HUD, GameOver, camera)
- Player physics (speed, jump, gravity)
- Enemy AI (speed, detection range, damage, chase behavior, idle when far)
- Fall-out detection (damage saat jatuh dari map)
- Camera (mouse sensitivity, shake method)
- SoundManager autoload
- Semua GameManager signal (7 signal)

### test_door.tscn — Door & Flow (10 test)
- Door creation (4 doors per level 1)
- Exactly 1 exit door
- Normal doors exist
- Door trigger signal
- Level transition flow (1 → 2, single increment)
- Dungeon regeneration per level
- Player persistence setelah transition
- Enemy spawn scaling per level
- Multiple transitions (sampai level 6)

---

## Bug Ditemukan & Diperbaiki

### 1. Kursor tidak muncul saat Game Over ✅ FIXED
**Severity:** High (game tidak bisa di-restart)
**Masalah:** Saat player mati, `get_tree().paused = true` membuat button Restart ikut ter-pause, dan mouse tetap captured.
**Fix:**
- `game_over.gd`: tambah `Input.mouse_mode = Input.MOUSE_MODE_VISIBLE`
- `game_over.tscn`: tambah `process_mode = 3` (PROCESS_MODE_ALWAYS) agar button responsif saat paused

### 2. SFX player hit terlalu panjang ✅ FIXED
**Severity:** Medium (audio numpuk)
**Masalah:** File `Player_hit.wav` durasi 5.49 detik, trigger tiap 0.5s → suara bertumpuk.
**Fix:**
- File dipotong manual jadi 0.25s (player) & 0.11s (enemy)
- `sound_manager.gd`: skip trigger kalau SFX yang sama masih playing

### 3. (False positive) Level naik 2x saat transition
**Severity:** None (bug di test, bukan game)
**Catatan:** Awalnya terlihat level 1 → 3 dalam satu trigger. Setelah investigasi, ternyata **test** yang double-trigger. Guard `_is_transitioning` di game sudah bekerja dengan benar — saat `is_transitioning=true`, trigger kedua di-ignore.

---

## Verifikasi Runtime
- Full game run headless (240 frame): **0 error, 0 warning** (selain leak artifact saat shutdown)
- Semua model ter-load: Warrior (player), GreenBlob (enemy), Kenney pickups, Kenney gate
- Semua audio ter-load: player-hit, enemy-hit, death, ambience

---

## Cara Menjalankan Test
```
# Godot executable
$GODOT = "C:\Users\ASUS\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"

# Jalankan masing-masing suite
& $GODOT --headless --path "D:\GAME\BuildingAGame" "res://test_runner.tscn"
& $GODOT --headless --path "D:\GAME\BuildingAGame" "res://test_advanced.tscn"
& $GODOT --headless --path "D:\GAME\BuildingAGame" "res://test_door.tscn"
```

---

## Yang TIDAK Tercakup (perlu test manual)
- Visual rendering (model orientation, animasi halus)
- Feel gameplay (kamera nyaman, gerak responsif)
- Audio mixing (volume balance antar SFX)
- UI layout pada resolusi berbeda
- Kontrol mouse & keyboard interaktif
