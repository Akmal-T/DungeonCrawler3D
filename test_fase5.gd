extends Node
## Fase 5 test: PlayerStats, UpgradePool, dash, integration

var _results: Array[String] = []
var _passed: int = 0
var _failed: int = 0

func _ready():
	print("\n=== FASE 5 TEST (Growth & Progression) ===")
	_run.call_deferred()

func _run():
	await get_tree().process_frame

	# --- PlayerStats ---
	_print_header("PlayerStats Basic")
	var s = PlayerStats.new()
	_ok(s.max_health() == 100, "Base max HP = 100 (got %d)" % s.max_health())
	_ok(s.damage(100, 100) == 10.0, "Base damage = 10 (got %s)" % s.damage(100, 100))
	_ok(s.speed() == 6.0, "Base speed = 6 (got %s)" % s.speed())
	_ok(abs(s.attack_cooldown() - 0.5) < 0.001, "Base attack cooldown = 0.5")

	# --- Bonus stacking ---
	_print_header("Stat Stacking")
	s.bonus_max_health += 25
	s.bonus_damage += 3.0
	s.bonus_speed_mult += 0.10
	_ok(s.max_health() == 125, "Max HP after +25 = 125 (got %d)" % s.max_health())
	_ok(s.damage(125, 125) == 13.0, "Damage after +3 = 13 (got %s)" % s.damage(125, 125))
	_ok(abs(s.speed() - 6.6) < 0.01, "Speed after +10%% = 6.6 (got %s)" % s.speed())

	# --- Attack speed ---
	s.bonus_attack_speed += 0.5  # +50% -> cooldown / 1.5
	var expected_cd = 0.5 / 1.5
	_ok(abs(s.attack_cooldown() - expected_cd) < 0.001, "Attack cooldown w/ +50%% attack speed = %.3f (got %.3f)" % [expected_cd, s.attack_cooldown()])

	# --- Crit ---
	_print_header("Crit System")
	s.crit_chance = 1.0  # always crit
	var roll = s.roll_damage(125, 125)
	_ok(roll.is_crit, "100% crit chance always crits")
	_ok(roll.damage > s.damage(125, 125), "Crit damage > base damage (%.1f > %.1f)" % [roll.damage, s.damage(125, 125)])

	# --- Low HP damage boost ---
	_print_header("Low HP Boost")
	s.low_hp_damage_boost = 0.40
	var high_hp_dmg = s.damage(100, 100)  # above 30%
	var low_hp_dmg = s.damage(20, 100)    # below 30%
	_ok(low_hp_dmg > high_hp_dmg, "Low HP damage > high HP damage (%.1f > %.1f)" % [low_hp_dmg, high_hp_dmg])

	# --- Reset ---
	_print_header("Reset")
	s.reset()
	_ok(s.max_health() == 100, "After reset max HP = 100 (got %d)" % s.max_health())
	_ok(s.bonus_damage == 0.0, "After reset damage bonus = 0")

	# --- Upgrade Pool ---
	_print_header("Upgrade Pool")
	var pool = UpgradePool.get_all()
	_ok(pool.size() >= 15, "Pool has >=15 upgrades (got %d)" % pool.size())
	# Verify all have required fields
	var all_valid = true
	for upg in pool:
		if not upg.has("id") or not upg.has("name") or not upg.has("apply") or not upg.has("max_stacks"):
			all_valid = false
	_ok(all_valid, "All upgrades have required fields")

	# --- Random choices ---
	_print_header("Random Choices")
	var choices = UpgradePool.get_random_choices(3, {})
	_ok(choices.size() == 3, "Returns 3 choices (got %d)" % choices.size())
	# With maxed upgrades, they should be filtered
	var taken = {}
	for upg in pool:
		if upg.max_stacks > 0:
			taken[upg.id] = upg.max_stacks
	var choices2 = UpgradePool.get_random_choices(3, taken)
	# Only unlimited-stack upgrades remain
	var all_unlimited = true
	for c in choices2:
		if c.max_stacks != 0:
			all_unlimited = false
	_ok(all_unlimited, "Maxed-stack upgrades filtered out")

	# --- Apply upgrade ---
	_print_header("Apply Upgrade")
	GameManager.reset_game()
	var hp_before = GameManager.stats.max_health()
	var dmg_upg = null
	for upg in pool:
		if upg.id == "max_health":
			dmg_upg = upg
			break
	if dmg_upg:
		GameManager.apply_upgrade(dmg_upg)
		_ok(GameManager.stats.max_health() > hp_before, "max_health upgrade applied (%d -> %d)" % [hp_before, GameManager.stats.max_health()])
		_ok(GameManager.upgrades_taken.has("max_health"), "upgrades_taken tracks max_health")

	# --- Dash (integration) ---
	_print_header("Dash System")
	var world_scene = load("res://Scenes/Dungeon/world.tscn")
	var world = world_scene.instantiate()
	get_tree().root.add_child(world)
	await get_tree().process_frame
	await get_tree().physics_frame
	var player = world.get_node_or_null("Player")
	_ok(player != null, "Player found")
	if player:
		_ok(player.has_method("get_dash_cooldown_ratio"), "Player has get_dash_cooldown_ratio")
		_ok(player.is_dash_ready(), "Dash ready at start")
		_ok(player.get("dash_speed") != null, "Player has dash_speed property")
		_ok(player.get("dash_duration") != null, "Player has dash_duration")
		# Trigger dash
		player._start_dash()
		await get_tree().physics_frame
		_ok(player._is_dashing, "Dash active after start")
		_ok(player.get_dash_cooldown_ratio() > 0.0, "Dash on cooldown after use")
		# Wait for dash to end
		await get_tree().create_timer(0.4).timeout
		_ok(not player._is_dashing, "Dash ended after duration")

	# --- HUD DashBar ---
	_print_header("HUD Dash Bar")
	var hud = world.get_node_or_null("HUD")
	_ok(hud != null, "HUD found")
	if hud:
		var dash_bar = hud.get_node_or_null("MarginContainer/VBoxContainer/DashBar")
		_ok(dash_bar != null, "DashBar exists in HUD")

	# --- Upgrade Selection UI ---
	_print_header("Upgrade Selection UI")
	var us = world.get_node_or_null("UpgradeSelection")
	_ok(us != null, "UpgradeSelection node exists")
	if us:
		_ok(us.has_method("_show_selection"), "Has _show_selection method")
		_ok(not us.visible, "Hidden at start")

	# --- Summary ---
	print("\n" + "=".repeat(50))
	print("RESULT: %d passed, %d failed" % [_passed, _failed])
	print("=".repeat(50) + "\n")
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()

func _print_header(name: String):
	print("\n[%s]" % name)

func _ok(cond: bool, msg: String):
	if cond:
		_passed += 1
		_results.append("  PASS: %s" % msg)
		print("  PASS: %s" % msg)
	else:
		_failed += 1
		_results.append("  FAIL: %s" % msg)
		print("  FAIL: %s" % msg)
