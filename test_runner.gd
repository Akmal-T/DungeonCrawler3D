extends Node
## Integration test untuk Dungeon Crawler 3D (linear, async-safe)

var _test_results: Array[String] = []
var _passed: int = 0
var _failed: int = 0

func _ready():
	print("\n=== INTEGRATION TEST ===")
	_run_all.call_deferred()

func _run_all():
	await get_tree().process_frame
	var ok := true

	# --- 1. Scene Load ---
	_print_header("Scene Load")
	var world_scene = load("res://Scenes/Dungeon/world.tscn")
	if world_scene == null:
		_ok(false, "World scene failed to load"); ok = false
	var world = world_scene.instantiate()
	get_tree().root.add_child(world)
	await get_tree().process_frame
	var player = world.get_node_or_null("Player")
	var dm = world.get_node_or_null("DungeonManager")
	_ok(player != null, "Player found")
	_ok(dm != null, "DungeonManager found")

	# --- 2. GameManager ---
	_print_header("GameManager Init")
	_ok(GameManager.current_level == 1, "Level = 1 (got %d)" % GameManager.current_level)
	_ok(GameManager.player_current_health == 100, "HP = 100 (got %d)" % GameManager.player_current_health)
	_ok(GameManager.score == 0, "Score = 0 (got %d)" % GameManager.score)

	# --- 3. Dungeon ---
	_print_header("Dungeon Generation")
	var rooms = dm.get_child_count()
	_ok(rooms >= 3, "Rooms >= 3 (got %d)" % rooms)

	# --- 4. Player ---
	_print_header("Player State")
	_ok(player.is_in_group("player"), "Player in group")
	var mr = player.get_node_or_null("MeshRoot")
	_ok(mr != null, "MeshRoot exists")
	_ok(mr != null and mr.get_node_or_null("Warrior") != null, "Warrior model present")

	# --- 5. Enemies ---
	_print_header("Enemy Spawn")
	var enemies = get_tree().get_nodes_in_group("enemies")
	_ok(enemies.size() >= 1, "Enemies spawned (got %d)" % enemies.size())
	if enemies.size() > 0:
		var e = enemies[0]
		_ok(e.has_method("take_damage"), "Enemy has take_damage")
		_ok(e.has_method("die"), "Enemy has die")

	# --- 6. Combat ---
	_print_header("Combat System")
	if enemies.size() > 0:
		var e = enemies[0]
		var hp0 = e.get("_current_health")
		e.take_damage(int(GameManager.get_player_damage()))
		await get_tree().process_frame
		var hp1 = e.get("_current_health")
		_ok(hp1 < hp0, "Enemy took damage (%s -> %s)" % [hp0, hp1])
		var score0 = GameManager.score
		e.take_damage(100)
		await get_tree().process_frame
		_ok(GameManager.score > score0, "Score increased on kill")

	# --- 7. Pickup/Heal ---
	_print_header("Pickup System")
	var hp_before = GameManager.player_current_health
	GameManager.damage_player(30)
	await get_tree().process_frame
	_ok(GameManager.player_current_health < hp_before, "Damage works")
	var hp_mid = GameManager.player_current_health
	GameManager.heal_player(20)
	await get_tree().process_frame
	_ok(GameManager.player_current_health > hp_mid, "Heal works")

	# --- 8. Level Transition ---
	_print_header("Level Transition")
	var lvl0 = GameManager.current_level
	var score_before_next = GameManager.score
	GameManager.next_level()
	await get_tree().process_frame
	_ok(GameManager.current_level == lvl0 + 1, "Level incremented (%d -> %d)" % [lvl0, GameManager.current_level])
	_ok(GameManager.score > score_before_next, "Score increased on level up")

	# --- 9. Game Over ---
	_print_header("Game Over")
	for e in get_tree().get_nodes_in_group("enemies"):
		e.set_physics_process(false)
	GameManager.player_current_health = GameManager.get_player_max_health()
	await get_tree().process_frame
	GameManager.damage_player(GameManager.get_player_max_health() + 50)
	await get_tree().process_frame
	_ok(GameManager.player_current_health == 0, "HP reached 0 (got %d)" % GameManager.player_current_health)
	var died_signal = [false]
	GameManager.player_died.connect(func(): died_signal[0] = true)
	GameManager.damage_player(10)
	await get_tree().process_frame
	_ok(died_signal[0], "player_died signal emitted")

	# --- Summary ---
	print("\n" + "=".repeat(50))
	for r in _test_results:
		print(r)
	print("-".repeat(50))
	print("RESULT: %d passed, %d failed" % [_passed, _failed])
	print("=".repeat(50) + "\n")
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()

func _print_header(name: String):
	print("\n[%s]" % name)

func _ok(cond: bool, msg: String):
	if cond:
		_passed += 1
		_test_results.append("  PASS: %s" % msg)
		print("  PASS: %s" % msg)
	else:
		_failed += 1
		_test_results.append("  FAIL: %s" % msg)
		print("  FAIL: %s" % msg)
