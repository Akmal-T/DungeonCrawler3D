extends Node
## Integration test lanjutan - physics, AI, doors, edge cases

var _results: Array[String] = []
var _passed: int = 0
var _failed: int = 0

func _ready():
	print("\n=== ADVANCED INTEGRATION TEST ===")
	_run.call_deferred()

func _run():
	await get_tree().process_frame
	var world_scene = load("res://Scenes/Dungeon/world.tscn")
	var world = world_scene.instantiate()
	get_tree().root.add_child(world)
	await get_tree().process_frame
	await get_tree().physics_frame

	var player = world.get_node_or_null("Player")
	var dm = world.get_node_or_null("DungeonManager")

	# --- Scene structure ---
	_print_header("Scene Structure")
	_ok(world.get_node_or_null("WorldEnvironment") != null, "WorldEnvironment exists")
	_ok(world.get_node_or_null("DirectionalLight3D") != null, "DirectionalLight exists")
	_ok(world.get_node_or_null("HUD") != null, "HUD exists")
	_ok(world.get_node_or_null("GameOver") != null, "GameOver exists")
	_ok(player.get_node_or_null("CameraPivot") != null, "CameraPivot exists")
	_ok(player.get_node_or_null("CameraPivot/Camera3D") != null, "Camera3D exists")

	# --- Player physics ---
	_print_header("Player Physics")
	_ok(player.get("speed") != null and player.speed > 0, "Player speed > 0")
	_ok(player.get("jump_velocity") != null and player.jump_velocity > 0, "Jump velocity > 0")
	# Test gravity: tempatkan player di udara, cek jatuh
	var start_y = player.global_position.y
	player.global_position.y += 5.0
	player.velocity = Vector3.ZERO
	for i in range(10):
		await get_tree().physics_frame
	_ok(player.velocity.y < 0, "Gravity applied (velocity.y=%0.2f)" % player.velocity.y)

	# --- Enemy AI ---
	_print_header("Enemy AI")
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() > 0:
		var e = enemies[0]
		_ok(e.get("speed") != null and e.speed > 0, "Enemy speed > 0")
		_ok(e.get("detection_range") != null and e.detection_range > 0, "Enemy detection range > 0")
		_ok(e.get("damage") != null and e.damage > 0, "Enemy damage > 0")
		# Test chase: posisikan enemy dekat player, cek gerak mendekat
		e.global_position = player.global_position + Vector3(5, 0, 0)
		e.velocity = Vector3.ZERO
		await get_tree().physics_frame
		await get_tree().physics_frame
		var dist_after = (e.global_position - player.global_position).length()
		_ok(dist_after < 5.0, "Enemy chases player (dist %0.2f)" % dist_after)
		# Test detection range: jauhkan enemy
		e.global_position = player.global_position + Vector3(100, 0, 0)
		e.velocity = Vector3.ZERO
		await get_tree().physics_frame
		_ok(abs(e.velocity.x) < 0.1 and abs(e.velocity.z) < 0.1, "Enemy idle when far away")

	# --- Player fall-out ---
	_print_header("Fall-Out Detection")
	GameManager.player_current_health = 100
	player.global_position = Vector3(0, -100, 0)
	await get_tree().physics_frame
	await get_tree().process_frame
	_ok(GameManager.player_current_health < 100, "Fall-out damages player (HP=%d)" % GameManager.player_current_health)

	# --- Camera orbit ---
	_print_header("Camera")
	var pivot = player.get_node_or_null("CameraPivot")
	_ok(pivot != null and pivot.get("mouse_sensitivity") != null, "Camera has mouse_sensitivity")
	_ok(pivot != null and pivot.has_method("shake"), "Camera has shake method")

	# --- SoundManager ---
	_print_header("SoundManager")
	_ok(SoundManager != null, "SoundManager autoload exists")
	_ok(SoundManager.has_method("_play_sfx"), "SoundManager has _play_sfx")

	# --- Signal connections ---
	_print_header("Signals")
	var gm_signals = ["player_died", "level_completed", "health_changed", "level_changed", "score_changed", "player_hit", "enemy_hit"]
	for sig in gm_signals:
		_ok(GameManager.has_signal(sig), "GameManager.%s signal exists" % sig)

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
