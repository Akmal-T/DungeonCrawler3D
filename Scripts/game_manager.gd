extends Node
## GameManager singleton — state global game.

const PlayerStats = preload("res://Scripts/player_stats.gd")
const UpgradePool = preload("res://Scripts/upgrade_pool.gd")

signal player_died
signal level_completed
signal health_changed(current_health, max_health)
signal level_changed(new_level)
signal score_changed(new_score)
signal player_hit
signal enemy_hit
signal upgrade_applied(upgrade_id)

var current_level: int = 1
var player_current_health: int = 100
var score: int = 0
var stats: PlayerStats = PlayerStats.new()
var upgrades_taken: Dictionary = {}  # upgrade_id -> stack count

var _is_invulnerable: bool = false
var _invuln_timer: float = 0.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

## Max HP — selalu dari stats.
func get_player_max_health() -> int:
	return stats.max_health()

## Damage — computed dari stats (termasuk low-HP boost).
func get_player_damage() -> float:
	return stats.damage(player_current_health, stats.max_health())

func reset_game():
	current_level = 1
	player_current_health = stats.max_health()
	score = 0
	stats.reset()
	player_current_health = stats.max_health()
	upgrades_taken.clear()
	level_changed.emit(current_level)
	score_changed.emit(score)
	health_changed.emit(player_current_health, stats.max_health())

func damage_player(amount: int):
	if _is_invulnerable:
		return
	# Shield absorb dulu
	if stats.shield_current > 0:
		var absorbed: int = min(stats.shield_current, amount)
		stats.shield_current -= absorbed
		amount -= absorbed
		if amount <= 0:
			health_changed.emit(player_current_health, stats.max_health())
			return
	player_current_health = max(0, player_current_health - amount)
	health_changed.emit(player_current_health, stats.max_health())
	player_hit.emit()
	if player_current_health <= 0:
		player_died.emit()

func heal_player(amount: int):
	player_current_health = min(player_current_health + amount, stats.max_health())
	health_changed.emit(player_current_health, stats.max_health())

## Set i-frames (dipakai dash).
func set_invulnerable(duration: float) -> void:
	_is_invulnerable = true
	_invuln_timer = duration

func _process(delta: float) -> void:
	# I-frame timer
	if _is_invulnerable:
		_invuln_timer -= delta
		if _invuln_timer <= 0.0:
			_is_invulnerable = false
	# HP regen
	if stats.health_regen > 0.0 and player_current_health > 0 and player_current_health < stats.max_health():
		var regen_amount := stats.health_regen * delta
		if regen_amount > 0.0:
			player_current_health = min(stats.max_health(), player_current_health + int(ceil(regen_amount)))
			health_changed.emit(player_current_health, stats.max_health())

## Terapkan upgrade dari pool.
func apply_upgrade(upgrade: Dictionary) -> void:
	var id: String = upgrade.get("id", "")
	var apply_fn: Callable = upgrade.get("apply")
	if apply_fn.is_valid():
		apply_fn.call(stats)
	upgrades_taken[id] = upgrades_taken.get(id, 0) + 1
	upgrade_applied.emit(id)
	health_changed.emit(player_current_health, stats.max_health())

## Regen lifesteal (dipanggil player setelah hit).
func apply_lifesteal(damage_dealt: float) -> void:
	if stats.lifesteal > 0.0:
		var heal_amount := int(ceil(damage_dealt * stats.lifesteal))
		if heal_amount > 0:
			heal_player(heal_amount)

func next_level():
	current_level += 1
	score += 100 * current_level
	# Recharge shield tiap level
	if stats.shield > 0:
		stats.shield_current = stats.shield
	level_changed.emit(current_level)
	score_changed.emit(score)
	health_changed.emit(player_current_health, stats.max_health())
	level_completed.emit()
