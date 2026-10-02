extends RefCounted
class_name UpgradePool
## UpgradePool: daftar semua upgrade + logic apply.
## Menggunakan method reference (bukan lambda multi-line) untuk menghindari
## batasan parser GDScript pada lambda di dalam dictionary literal.

static func get_all() -> Array:
	return [
		# ===== BASIC STATS =====
		_common("max_health", "Vitality", "+25 Max HP, langsung heal 25", 0, _apply_max_health),
		_common("damage", "Sharpness", "+3 Attack Damage", 0, _apply_damage),
		_common("speed", "Swiftness", "+8% Movement Speed", 0, _apply_speed),
		_common("attack_speed", "Ferocity", "+10% Attack Speed", 0, _apply_attack_speed),
		_common("attack_range", "Reach", "+0.4 Attack Range", 5, _apply_attack_range),
		# ===== ADVANCED STATS =====
		_rare("regen", "Regeneration", "Regenerate 1 HP per detik", 5, _apply_regen),
		_rare("lifesteal", "Vampirism", "Heal 15% dari damage yang diberikan", 4, _apply_lifesteal),
		_rare("crit_chance", "Precision", "+10% Critical Chance", 8, _apply_crit_chance),
		_rare("crit_damage", "Deadly Strikes", "+50% Critical Damage", 6, _apply_crit_damage),
		_epic("cleave", "Cleave", "Serangan mengenai musuh sekitar (radius 2.0)", 3, _apply_cleave),
		_rare("shield", "Arcane Shield", "+30 Shield (recharge tiap level)", 5, _apply_shield),
		# ===== UNIQUE / SYNERGY =====
		_rare("thorns", "Thorns", "Musuh yang menyerang menerima 5 damage", 6, _apply_thorns),
		_epic("low_hp_damage", "Berserker", "+40% damage saat HP di bawah 30%", 3, _apply_low_hp_damage),
		_rare("kill_speed", "Bloodlust", "+15% speed setelah membunuh musuh", 4, _apply_kill_speed),
		_rare("dash_master", "Dash Master", "-20% Dash cooldown", 4, _apply_dash_master),
		_epic("projectile", "Blade Wave", "Serangan melepas proyektil (50% damage)", 3, _apply_projectile),
		_common("heal_now", "Mending", "Heal penuh 50 HP sekarang", 0, _apply_heal_now),
	]

static func _common(id: String, name: String, desc: String, max_stacks: int, apply: Callable) -> Dictionary:
	return {"id": id, "name": name, "description": desc, "rarity": "common", "max_stacks": max_stacks, "apply": apply}

static func _rare(id: String, name: String, desc: String, max_stacks: int, apply: Callable) -> Dictionary:
	return {"id": id, "name": name, "description": desc, "rarity": "rare", "max_stacks": max_stacks, "apply": apply}

static func _epic(id: String, name: String, desc: String, max_stacks: int, apply: Callable) -> Dictionary:
	return {"id": id, "name": name, "description": desc, "rarity": "epic", "max_stacks": max_stacks, "apply": apply}

# --- Apply functions ---
static func _apply_max_health(s: PlayerStats) -> void:
	s.bonus_max_health += 25
	GameManager.heal_player(25)

static func _apply_damage(s: PlayerStats) -> void:
	s.bonus_damage += 3.0

static func _apply_speed(s: PlayerStats) -> void:
	s.bonus_speed_mult += 0.08

static func _apply_attack_speed(s: PlayerStats) -> void:
	s.bonus_attack_speed += 0.10

static func _apply_attack_range(s: PlayerStats) -> void:
	s.bonus_attack_range += 0.4

static func _apply_regen(s: PlayerStats) -> void:
	s.health_regen += 1.0

static func _apply_lifesteal(s: PlayerStats) -> void:
	s.lifesteal += 0.15

static func _apply_crit_chance(s: PlayerStats) -> void:
	s.crit_chance = min(1.0, s.crit_chance + 0.10)

static func _apply_crit_damage(s: PlayerStats) -> void:
	s.crit_damage += 0.5

static func _apply_cleave(s: PlayerStats) -> void:
	s.cleave_radius += 2.0

static func _apply_shield(s: PlayerStats) -> void:
	s.shield += 30
	s.shield_current = s.shield

static func _apply_thorns(s: PlayerStats) -> void:
	s.thorns += 5

static func _apply_low_hp_damage(s: PlayerStats) -> void:
	s.low_hp_damage_boost += 0.40

static func _apply_kill_speed(s: PlayerStats) -> void:
	s.kill_speed_boost += 0.15

static func _apply_dash_master(s: PlayerStats) -> void:
	s.dash_cooldown_mult *= 0.8

static func _apply_projectile(s: PlayerStats) -> void:
	s.projectile_enabled = true
	s.projectile_damage_mult += 0.25

static func _apply_heal_now(_s: PlayerStats) -> void:
	GameManager.heal_player(50)

## Ambil N upgrade acak, filter berdasarkan stack yang sudah diambil.
static func get_random_choices(count: int, taken: Dictionary) -> Array:
	var pool := get_all()
	var valid := []
	for upg in pool:
		var stacks: int = taken.get(upg.id, 0)
		if upg.max_stacks == 0 or stacks < upg.max_stacks:
			valid.append(upg)
	valid.shuffle()
	var result := []
	for i in range(min(count, valid.size())):
		result.append(valid[i])
	return result
