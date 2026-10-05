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
## config: Dictionary berisi visual config (wall_height, door_height, dll)
## return: Dictionary berisi info ruangan (bounds, door positions)
static func build_room(parent: Node3D, room_size: int, doors: Dictionary, config: Dictionary = {}) -> Dictionary:
	var half := room_size / 2.0

	_build_floor(parent, room_size)
	_build_walls(parent, room_size, doors, config)
	_build_columns(parent, half, config)
	_build_props(parent, room_size, config)
	_build_lighting(parent, half, config)

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

static func _build_walls(parent: Node3D, room_size: int, doors: Dictionary, config: Dictionary) -> void:
	var walls_node := Node3D.new()
	walls_node.name = "Walls"
	parent.add_child(walls_node)

	var half := room_size / 2.0
	var door_center := room_size / 2
	var door_half := DOOR_WIDTH / 2.0

	for i in room_size:
		var offset := i - room_size / 2.0 + 0.5

		var is_door: bool = abs(i - door_center) < door_half or abs(i - door_center + 0.5) < door_half

		_add_wall_tile(walls_node, Vector3(offset, 0, -half), 0.0, is_door and doors.get("north", false), config)
		_add_wall_tile(walls_node, Vector3(offset, 0, half), PI, is_door and doors.get("south", false), config)
		_add_wall_tile(walls_node, Vector3(-half, 0, offset), PI / 2.0, is_door and doors.get("west", false), config)
		_add_wall_tile(walls_node, Vector3(half, 0, offset), -PI / 2.0, is_door and doors.get("east", false), config)

static func _add_wall_tile(parent: Node3D, pos: Vector3, rot_y: float, is_door: bool, config: Dictionary) -> void:
	var wall_height: float = config.get("wall_height", 6.0)
	var wall_scale_xz: float = config.get("wall_scale_xz", 1.0)
	var wall_col_height: float = config.get("wall_collision_height", 6.6)
	var wall_col_thickness: float = config.get("wall_collision_thickness", 0.3)
	var door_height: float = config.get("door_height", 6.0)
	var door_scale_xz: float = config.get("door_scale_xz", 1.0)

	if is_door:
		var door_vis := _instance("wall-opening", pos, rot_y)
		door_vis.scale = Vector3(door_scale_xz, door_height, door_scale_xz)
		parent.add_child(door_vis)
		return

	var body := StaticBody3D.new()
	body.position = pos
	body.rotation.y = rot_y
	parent.add_child(body)

	var wall := _instance("wall", Vector3(0, 0, 0), 0.0)
	wall.scale = Vector3(wall_scale_xz, wall_height, wall_scale_xz)
	body.add_child(wall)

	var col := CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	col.shape.size = Vector3(1.0, wall_col_height, wall_col_thickness)
	body.add_child(col)

static func _build_columns(parent: Node3D, half: float, config: Dictionary) -> void:
	var col_height: float = config.get("column_height", 6.0)
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
		col.scale = Vector3(1.0, col_height, 1.0)
		cols_node.add_child(col)

static func _build_props(parent: Node3D, room_size: int, config: Dictionary) -> void:
	var min_count: int = config.get("props_min_count", 0)
	var max_count: int = config.get("props_max_count", 3)
	if max_count < min_count:
		max_count = min_count
	var props_node := Node3D.new()
	props_node.name = "Props"
	parent.add_child(props_node)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var prop_scenes := ["barrel", "pot", "rocks", "stones"]
	var count := rng.randi_range(min_count, max_count)
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

static func _build_lighting(parent: Node3D, half: float, config: Dictionary) -> void:
	var light_height: float = config.get("room_light_height", 4.0)
	var light_range: float = config.get("room_light_range", 18.0)
	var light_energy: float = config.get("room_light_energy", 2.0)
	var light_color: Color = config.get("room_light_color", Color(1.0, 0.9, 0.75))
	var light_attenuation: float = config.get("room_light_attenuation", 1.0)
	var light_shadow: bool = config.get("room_light_shadow", false)
	var light := OmniLight3D.new()
	light.name = "RoomLight"
	light.light_color = light_color
	light.light_energy = light_energy
	light.omni_range = light_range
	light.omni_attenuation = light_attenuation
	light.shadow_enabled = light_shadow
	light.position = Vector3(0, light_height, 0)
	parent.add_child(light)
