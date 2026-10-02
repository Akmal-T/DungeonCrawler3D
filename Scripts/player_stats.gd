extends RefCounted
class_name PlayerStats
## PlayerStats: menyimpan semua stat player + logic upgrade.
## Dipegang oleh GameManager sebagai `stats`.

# --- Base stats ---
var base_max_health: int = 100
var base_damage: float = 10.0
var base_speed: float = 6.0
var base_attack_cooldown: float = 0.5
var base_attack_range: float = 2.5

# --- Bonus dari upgrade ---
var bonus_max_health: int = 0
var bonus_damage: float = 0.0
var bonus_speed_mult: float = 1.0        # multiplier
var bonus_attack_speed: float = 1.0      # multiplier (>1 = lebih cepat)
var bonus_attack_range: float = 0.0

# --- Advanced stats ---
var health_regen: float = 0.0            # HP per detik
var lifesteal: float = 0.0               # % damage jadi HP
var crit_chance: float = 0.0             # 0..1
var crit_damage: float = 2.0             # multiplier
var thorns: int = 0                      # damage balik ke penyerang
var shield: int = 0                      # absorb damage (max)
var shield_current: int = 0
var cleave_radius: float = 0.0           # area damage tambahan
var dash_cooldown_mult: float = 1.0
var low_hp_damage_boost: float = 0.0     # +damage saat HP < 30%
var kill_speed_boost: float = 0.0        # +speed sementara setelah kill (durasi fixed)

# --- Ranged ---
var projectile_enabled: bool = false
var projectile_damage_mult: float = 0.5

# --- Computed ---
func max_health() -> int:
	return base_max_health + bonus_max_health

func damage(current_health: int, max_health: int) -> float:
	var dmg := base_damage + bonus_damage
	if low_hp_damage_boost > 0.0 and current_health < max_health * 0.3:
		dmg *= (1.0 + low_hp_damage_boost)
	return dmg

func speed() -> float:
	return base_speed * bonus_speed_mult

func attack_cooldown() -> float:
	return base_attack_cooldown / max(0.1, bonus_attack_speed)

func attack_range() -> float:
	return base_attack_range + bonus_attack_range

func crit_multiplier() -> float:
	return crit_damage

## Roll a damage value with crit applied. Returns {damage, is_crit}
func roll_damage(current_health: int, max_health: int, override_base: float = -1.0) -> Dictionary:
	var dmg := damage(current_health, max_health) if override_base < 0.0 else override_base
	var is_crit := randf() < crit_chance
	if is_crit:
		dmg *= crit_damage
	return {"damage": dmg, "is_crit": is_crit}

## Reset ke kondisi awal (untuk new game).
func reset() -> void:
	bonus_max_health = 0
	bonus_damage = 0.0
	bonus_speed_mult = 1.0
	bonus_attack_speed = 1.0
	bonus_attack_range = 0.0
	health_regen = 0.0
	lifesteal = 0.0
	crit_chance = 0.0
	crit_damage = 2.0
	thorns = 0
	shield = 0
	shield_current = 0
	cleave_radius = 0.0
	dash_cooldown_mult = 1.0
	low_hp_damage_boost = 0.0
	kill_speed_boost = 0.0
	projectile_enabled = false
	projectile_damage_mult = 0.5
