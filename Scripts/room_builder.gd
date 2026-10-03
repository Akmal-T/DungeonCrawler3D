class_name RoomBuilder
extends RefCounted
## Membangun ruangan dungeon dari tile Kenney Mini Dungeon.
## Dipakai oleh DungeonManager untuk membuat ruangan secara programatik.

const ASSET_DIR := "res://Assets/Kenney_MiniDungeon/Models/GLB format/"

# Cache scene yang sudah di-load
static var _cache: Dictionary = {}

# Ukuran pintu (lebar lorong) dalam tile
const DOOR_WIDTH := 2

static func _get_scene(asset_name: String) -> PackedScene:
	if not _cache.has(asset_name):
		_cache[asset_name] = load(ASSET_DIR + asset_name + ".glb")
	return _cache[asset_name]

## Membangun ruangan lengkap di dalam node parent.
## room_size: ukuran dalam tile (mis. 12 = 12x12)
## doors: Dictionary { "north": bool, "south": bool, "east": bool, "west": bool }
## return: Dictionary berisi info ruangan (bounds, door positions)
static func build_room(parent: Node3D, room_size: int, doors: Dictionary) -> Dictionary:
	var half := room_size / 2.0

	_build_floor(parent, room_size)
	_build_walls(parent, room_size, doors)
	_build_columns(parent, half)
	_build_props(parent, room_size)

	# Hitung posisi pintu (global dari origin ruangan)
	var door_positions := {}
	if doors.get("north", false):
		door_positions["north"] = Vector3(0, 0, -half)
	if doors.get("south", false):
		door_positions["south"] = Vector3(0, 0, half)
	if doors.get("east", false):
		door_positions["east"] = Vector3(half, 0, 0)
	if doors.get("west", false):
		door_positions["west"] = Vector3(-half, 0, 0)

	return {
		"size": room_size,
		"half": half,
		"doors": door_positions,
	}

static func _instance(scene_name: String, pos: Vector3, rot_y: float = 0.0) -> Node3D:
	var packed := _get_scene(scene_name)
	var inst := packed.instantiate() as Node3D
	inst.position = pos
	inst.rotation.y = rot_y
	return inst

static func _build_floor(parent: Node3D, room_size: int) -> void:
	var floor_node := Node3D.new()
	floor_node.name = "Floor"
	parent.add_child(floor_node)
	
	# Add solid collision untuk lantai (1 StaticBody3D besar)
	var floor_body := StaticBody3D.new()
	floor_body.name = "FloorCollision"
	parent.add_child(floor_body)
	var floor_col := CollisionShape3D.new()
	floor_col.shape = BoxShape3D.new()
	floor_col.shape.size = Vector3(room_size, 0.2, room_size)
	floor_col.position = Vector3(0, -0.1, 0)
	floor_body.add_child(floor_col)
	
	# floor.glb pivot di corner (-0.5, -0.5), jadi offset +0.5 untuk align grid
	for x in room_size:
		for z in room_size:
			var scene := "floor" if ((x + z) % 2 == 0) else "floor-detail"
			var tile := _instance(scene, Vector3(x - room_size / 2.0 + 0.5, 0, z - room_size / 2.0 + 0.5))
			floor_node.add_child(tile)

static func _build_walls(parent: Node3D, room_size: int, doors: Dictionary) -> void:
	var walls_node := Node3D.new()
	walls_node.name = "Walls"
	parent.add_child(walls_node)

	var half := room_size / 2.0
	var door_center := room_size / 2  # index tengah
	var door_half := DOOR_WIDTH / 2.0

	# Setiap sisi: iterate dari -half..half
	for i in room_size:
		var offset := i - room_size / 2.0 + 0.5  # -5.5 .. 5.5 untuk 12

		# Cek apakah tile ini termasuk pintu
		var is_door: bool = abs(i - door_center) < door_half or abs(i - door_center + 0.5) < door_half

		# North (z = -half), wall menghadap +z
		_add_wall_tile(walls_node, Vector3(offset, 0, -half), 0.0, is_door and doors.get("north", false))
		# South (z = +half)
		_add_wall_tile(walls_node, Vector3(offset, 0, half), PI, is_door and doors.get("south", false))
		# West (x = -half)
		_add_wall_tile(walls_node, Vector3(-half, 0, offset), PI / 2.0, is_door and doors.get("west", false))
		# East (x = +half)
		_add_wall_tile(walls_node, Vector3(half, 0, offset), -PI / 2.0, is_door and doors.get("east", false))

static func _add_wall_tile(parent: Node3D, pos: Vector3, rot_y: float, is_door: bool) -> void:
	if is_door:
		return  # pintu dibiarkan terbuka, gate ditambah terpisah

	# StaticBody3D sebagai holder collision + visual
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation.y = rot_y
	parent.add_child(body)

	# Visual wall mesh
	var wall := _instance("wall", Vector3(0, 0, 0), 0.0)
	body.add_child(wall)

	# Solid collision box (tebal 0.3 agar pemain tidak tembus)
	var col := CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	col.shape.size = Vector3(1.0, 1.1, 0.3)
	body.add_child(col)

static func _build_columns(parent: Node3D, half: float) -> void:
	var cols_node := Node3D.new()
	cols_node.name = "Columns"
	parent.add_child(cols_node)
	var inset := half - 0.5
	var corners := [
		Vector3(-inset, 0, -inset),
		Vector3(inset, 0, -inset),
		Vector3(-inset, 0, inset),
		Vector3(inset, 0, inset),
	]
	for c in corners:
		var col := _instance("column", c)
		cols_node.add_child(col)

static func _build_props(parent: Node3D, room_size: int) -> void:
	var props_node := Node3D.new()
	props_node.name = "Props"
	parent.add_child(props_node)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var prop_scenes := ["barrel", "pot", "rocks", "stones"]
	var count := rng.randi_range(0, 3)
	var half := room_size / 2.0 - 2.0
	for i in count:
		var scene_name: String = prop_scenes[rng.randi() % prop_scenes.size()]
		var pos := Vector3(
			rng.randf_range(-half, half),
			0,
			rng.randf_range(-half, half)
		)
		var prop := _instance(scene_name, pos, rng.randf_range(0, TAU))
		props_node.add_child(prop)
