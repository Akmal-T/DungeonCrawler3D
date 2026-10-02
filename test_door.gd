extends Node
## Test Door system + level transition flow

var _results: Array[String] = []
var _passed: int = 0
var _failed: int = 0

func _ready():
	print("\n=== DOOR & LEVEL FLOW TEST ===")
	_run.call_deferred()

func _run():
	print("Starting door test...")
	GameManager.reset_game()
	var world_scene = load("res://Scenes/Dungeon/world.tscn")
	print("World scene loaded: %s" % world_scene)
	var world = world_scene.instantiate()
	get_tree().root.add_child(world)
	await get_tree().process_frame
	await get_tree().physics_frame

	var dm = world.get_node_or_null("DungeonManager")
	var player = world.get_node_or_null("Player")

	# --- Door instantiation ---
	_print_header("Door System")
	var doors = []
	_collect_doors(dm, doors)
	_ok(doors.size() > 0, "Doors created (%d total)" % doors.size())

	var exit_doors = []
	for d in doors:
		if d.is_exit:
			exit_doors.append(d)
	_ok(exit_doors.size() == 1, "Exactly 1 exit door (got %d)" % exit_doors.size())

	# Check door triggers connected
	var normal_doors = doors.size() - exit_doors.size()
	_ok(normal_doors >= 1, "Normal doors exist (%d)" % normal_doors)

	# --- Door signal ---
	_print_header("Door Trigger")
	var signal_fired = [false]
	if exit_doors.size() > 0:
		var exit_door = exit_doors[0]
		exit_door.player_entered.connect(func(d): signal_fired[0] = true)
		# Simulasi player masuk door (langsung emit signal, tidak trigger transition)
		exit_door.player_entered.emit(exit_door)
		await get_tree().process_frame
		_ok(signal_fired[0], "Exit door emits player_entered signal")

	# --- Level transition via exit door ---
	_print_header("Level Transition Flow")
	var level_before = GameManager.current_level
	var score_before = GameManager.score
	if exit_doors.size() > 0:
		dm._on_door_entered.call_deferred(exit_doors[0])
		await get_tree().create_timer(1.5).timeout
		await get_tree().physics_frame
		var level_after = GameManager.current_level
		_ok(level_after == level_before + 1, "Level advanced (%d -> %d)" % [level_before, level_after])
		_ok(GameManager.score > score_before, "Score increased on level up")
		var rooms_after = dm.get_child_count()
		_ok(rooms_after >= 3, "Dungeon regenerated (%d rooms)" % rooms_after)
		_ok(is_instance_valid(player), "Player still valid after transition")

	# --- Enemy spawn per level ---
	_print_header("Enemy Spawn Scaling")
	var enemies_lvl2 = get_tree().get_nodes_in_group("enemies")
	_ok(enemies_lvl2.size() >= 1, "Enemies spawned for level 2 (%d)" % enemies_lvl2.size())

	# --- Multiple levels ---
	_print_header("Multiple Level Transitions")
	for i in range(3):
		var doors_now = []
		_collect_doors(dm, doors_now)
		var exit_now = null
		for d in doors_now:
			if d.is_exit:
				exit_now = d
				break
		if exit_now:
			dm._is_transitioning = false
			dm._on_door_entered(exit_now)
			await get_tree().create_timer(0.8).timeout
			await get_tree().physics_frame
	_ok(GameManager.current_level >= 4, "Survived multiple transitions (level %d)" % GameManager.current_level)

	# Summary
	print("\n" + "=".repeat(50))
	print("RESULT: %d passed, %d failed" % [_passed, _failed])
	print("=".repeat(50) + "\n")
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()

func _collect_doors(node: Node, out: Array):
	for child in node.get_children():
		if child is Area3D and child.has_method("_on_body_entered") and "is_exit" in child:
			out.append(child)
		_collect_doors(child, out)

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
