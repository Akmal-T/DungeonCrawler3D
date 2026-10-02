extends Node
## GameManager singleton — state global game.

signal player_died
signal level_completed
signal health_changed(current_health, max_health)
signal level_changed(new_level)
signal score_changed(new_score)

var current_level: int = 1
var player_max_health: int = 100
var player_current_health: int = 100
var player_damage: float = 10.0
var player_speed_multiplier: float = 1.0
var score: int = 0
var upgrades: Array[String] = []

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func reset_game():
	current_level = 1
	player_max_health = 100
	player_current_health = 100
	player_damage = 10.0
	player_speed_multiplier = 1.0
	score = 0
	upgrades.clear()
	level_changed.emit(current_level)
	score_changed.emit(score)
	health_changed.emit(player_current_health, player_max_health)

func damage_player(amount: int):
	player_current_health = max(0, player_current_health - amount)
	health_changed.emit(player_current_health, player_max_health)
	if player_current_health <= 0:
		player_died.emit()

func heal_player(amount: int):
	player_current_health = min(player_current_health + amount, player_max_health)
	health_changed.emit(player_current_health, player_max_health)

func add_upgrade(upgrade_name: String):
	upgrades.append(upgrade_name)

func next_level():
	current_level += 1
	score += 100 * current_level
	level_changed.emit(current_level)
	score_changed.emit(score)
	level_completed.emit()
