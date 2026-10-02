extends CharacterBody3D

@export var speed: float = 6.0
@export var jump_velocity: float = 5.5
@export var acceleration: float = 12.0
@export var friction: float = 10.0
@export var rotation_speed: float = 12.0

@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _mesh_root: Node3D = $MeshRoot

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

func _ready() -> void:
	# Fallback: jika tidak berada di dalam world dungeon, spawn standar
	pass

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_jump()
	_handle_movement(delta)
	move_and_slide()
	_check_fall_out()

func _check_fall_out() -> void:
	# Jika jatuh terlalu jauh (keluar dungeon), restart level
	if global_position.y < -20.0:
		GameManager.damage_player(GameManager.player_current_health + 1)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

func _handle_movement(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_dir.length() < 0.01:
		_decelerate(delta)
		return

	# Arah gerak relatif terhadap rotasi kamera
	var camera_basis := _camera_pivot.global_transform.basis
	var forward := -camera_basis.z
	var right := camera_basis.x
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()

	var direction := (right * input_dir.x - forward * input_dir.y).normalized()
	var target_velocity := direction * speed * GameManager.player_speed_multiplier

	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)

	_face_direction(direction, delta)

func _decelerate(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	velocity.z = move_toward(velocity.z, 0.0, friction * delta)

func _face_direction(direction: Vector3, delta: float) -> void:
	if direction.length() < 0.01:
		return
	var target_angle := atan2(direction.x, direction.z)
	_mesh_root.rotation.y = lerp_angle(_mesh_root.rotation.y, target_angle, rotation_speed * delta)
