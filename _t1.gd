extends Node
const PlayerStats = preload("res://Scripts/player_stats.gd")
var stats: PlayerStats = PlayerStats.new()
var player_current_health: int = 100
func get_player_max_health() -> int:
	return stats.max_health()
func damage_player(amount: int):
	if stats.shield_current > 0:
		var absorbed: int = min(stats.shield_current, amount)
		stats.shield_current -= absorbed
		amount -= absorbed
	player_current_health = max(0, player_current_health - amount)
