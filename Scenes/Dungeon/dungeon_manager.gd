extends Node3D
## DungeonManager: generates a grid of connected rooms per level.

const DOOR_SCENE := preload("res://Scenes/Dungeon/door.tscn")
const ENEMY_SCENE := preload("res://Scenes/Enemies/enemy.tscn")

# Grid layout: 3x3 max
const GRID_SIZE := 3
const TILE_SIZE := 1.0

# Room size per level (in tiles)
func _room_size_for_level(level: int) -> int:
	return clampi(10 + (level - 1) * 2, 10, 16)

# Jumlah ruangan per level
func _room_count_for_level(level: int) -> int:
	return clampi(3 + (level - 1), 3, 9)

var _rooms: Array[Vector2i] = []       # daftar koordinat grid yang terisi
var _room_nodes: Dictionary = {}       # Vector2i -> Node3D
var _connections: Dictionary = {}      # Vector2i -> Array[String] (arah pintu)
var _exit_room: Vector2i               # ruangan dengan pintu exit
var _player: CharacterBody3D
var _rng := RandomNumberGenerator.new()
var _room_size: int = 12
var _spacing: float = 0.0
var _is_transitioning := false
var _fade: ColorRect

const FADE_TIME := 0.3

func setup(player: CharacterBody3D) -> void:
	_player = player
	_create_fade_overlay()
	_generate_dungeon(GameManager.current_level)

func _create_fade_overlay() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(_fade)

func _generate_dungeon(level: int) -> void:
	# Bersihkan dungeon lama (kecuali fade overlay)
	for child in get_children():
		if child == _fade.get_parent():
			continue
		child.queue_free()
	_rooms.clear()
	_room_nodes.clear()
	_connections.clear()

	_rng.seed = hash("dungeon_level_%d" % level)
	_room_size = _room_size_for_level(level)
	_spacing = _room_size  # ruangan bersebelahan tepat berdempet
	var count := _room_count_for_level(level)

	# Generate layout grid memakai random walk dari tengah
	_generate_layout(count)

	# Hitung koneksi (ruangan bertetangga)
	_compute_connections()
	
	# Tentukan ruangan terjauh sebagai exit (paling jauh dari start)
	_find_exit_room()

	# Bangun tiap ruangan
	for cell in _rooms:
		var room_node := Node3D.new()
		room_node.name = "Room_%d_%d" % [cell.x, cell.y]
		room_node.position = _cell_to_world(cell)
		add_child(room_node)
		var doors := _doors_for_cell(cell)
		RoomBuilder.build_room(room_node, _room_size, doors)
		_add_door_triggers(room_node, doors, cell == _exit_room)
		_spawn_enemies(room_node, cell, level)
		_room_nodes[cell] = room_node

	# Pindahkan player ke ruangan start (tengah)
	var start_cell := _rooms[0]
	_player.global_position = _cell_to_world(start_cell) + Vector3(0, 2, 0)

func _generate_layout(count: int) -> void:
	var center := Vector2i(GRID_SIZE / 2, GRID_SIZE / 2)
	_rooms.append(center)
	var frontier := [center]
	var attempts := 0
	while _rooms.size() < count and attempts < 200:
		attempts += 1
		var from: Vector2i = frontier[_rng.randi() % frontier.size()]
		var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
		var d: Vector2i = dirs[_rng.randi() % dirs.size()]
		var next := from + d
		if next.x < 0 or next.x >= GRID_SIZE or next.y < 0 or next.y >= GRID_SIZE:
			continue
		if _rooms.has(next):
			continue
		_rooms.append(next)
		frontier.append(next)

func _compute_connections() -> void:
	for cell in _rooms:
		var conns: Array[String] = []
		if _rooms.has(cell + Vector2i(0, -1)):
			conns.append("north")
		if _rooms.has(cell + Vector2i(0, 1)):
			conns.append("south")
		if _rooms.has(cell + Vector2i(1, 0)):
			conns.append("east")
		if _rooms.has(cell + Vector2i(-1, 0)):
			conns.append("west")
		_connections[cell] = conns

func _doors_for_cell(cell: Vector2i) -> Dictionary:
	var conns: Array = _connections.get(cell, [])
	return {
		"north": conns.has("north"),
		"south": conns.has("south"),
		"east": conns.has("east"),
		"west": conns.has("west"),
	}

func _find_exit_room() -> void:
	# Pilih ruangan dengan jarak Manhattan terjauh dari start (_rooms[0])
	var start: Vector2i = _rooms[0]
	var best: Vector2i = start
	var best_dist := -1
	for cell in _rooms:
		var dist: int = abs(cell.x - start.x) + abs(cell.y - start.y)
		if dist > best_dist:
			best_dist = dist
			best = cell
	_exit_room = best

func _cell_to_world(cell: Vector2i) -> Vector3:
	# Grid tumbuh: x = kolom, y = baris
	return Vector3(cell.x * _spacing, 0, cell.y * _spacing)

func _add_door_triggers(room_node: Node3D, doors: Dictionary, room_is_exit: bool) -> void:
	var half := _room_size / 2.0
	# Hanya ruangan exit yang punya pintu exit. Ruangan lain = pintu biasa (eksplor).
	# Jika ruangan exit, pilih salah satu pintu yang ada sebagai pintu exit.
	var exit_dir := _pick_exit_direction(doors) if room_is_exit else ""

	for dir in doors.keys():
		if not doors[dir]:
			continue
		var door: Area3D = DOOR_SCENE.instantiate()
		door.direction = dir
		door.is_exit = (dir == exit_dir)
		match dir:
			"north": door.position = Vector3(0, 0, -half)
			"south": door.position = Vector3(0, 0, half)
			"east": door.position = Vector3(half, 0, 0)
			"west": door.position = Vector3(-half, 0, 0)
		door.player_entered.connect(_on_door_entered)
		room_node.add_child(door)

func _spawn_enemies(room_node: Node3D, room_cell: Vector2i, level: int) -> void:
	# Skip spawn di start room dan exit room
	if room_cell == _rooms[0] or room_cell == _exit_room:
		return

	# Enemy count: 1 + (level-1)/2
	var enemy_count: int = 1 + ((level - 1) / 2)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in enemy_count:
		var enemy := ENEMY_SCENE.instantiate()
		enemy.speed = 2.0 + (level * 0.2)
		enemy.damage = 10 + (level * 2)
		enemy.position = Vector3(
			rng.randf_range(-_room_size / 2.0 + 2, _room_size / 2.0 - 2),
			0.5,
			rng.randf_range(-_room_size / 2.0 + 2, _room_size / 2.0 - 2)
		)
		room_node.add_child(enemy)

func _pick_exit_direction(doors: Dictionary) -> String:
	# Pilih arah pintu pertama yang aktif sebagai exit
	for dir in ["north", "south", "east", "west"]:
		if doors.get(dir, false):
			return dir
	return ""

func _on_door_entered(door) -> void:
	if _is_transitioning:
		return
	if not door.is_exit:
		return  # pintu biasa: hanya untuk eksplor, tidak pindah level
	_is_transitioning = true
	_transition_to_next_level()

func _transition_to_next_level() -> void:
	# Fade out
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, FADE_TIME)
	await tween.finished

	# Naik level & regenerate
	GameManager.next_level()
	_generate_dungeon(GameManager.current_level)

	# Fade in
	var tween2 := create_tween()
	tween2.tween_property(_fade, "color:a", 0.0, FADE_TIME)
	await tween2.finished

	_is_transitioning = false
