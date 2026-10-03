extends CharacterBody3D

@export var speed: float = 6.0
@export var jump_velocity: float = 5.5
@export var acceleration: float = 12.0
@export var friction: float = 10.0
@export var rotation_speed: float = 12.0
@export var attack_range: float = 2.5
@export var attack_cooldown: float = 0.5
@export var attack_radius: float = 1.2

@export_category("Dash")
@export var dash_speed: float = 20.0
@export var dash_duration: float = 0.25
@export var dash_cooldown: float = 2.0
@export var dash_invuln_time: float = 0.35

@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _mesh_root: Node3D = $MeshRoot
@onready var _anim: AnimationPlayer = $MeshRoot/Warrior/AnimationPlayer

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _last_attack_time: float = 0.0
var _is_attacking: bool = false
var _current_anim: String = ""

# Dash state
var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO

func get_dash_cooldown_ratio() -> float:
	## 0.0 = siap, 1.0 = baru dipakai
	var cd := dash_cooldown * GameManager.stats.dash_cooldown_mult
	if cd <= 0.0:
		return 0.0
	return clamp(_dash_cooldown_timer / cd, 0.0, 1.0)

func is_dash_ready() -> bool:
	return _dash_cooldown_timer <= 0.0 and not _is_dashing

func _ready() -> void:
	if _anim:
		_play_anim("Idle")
		_anim.animation_finished.connect(_on_anim_finished)

func _physics_process(delta: float) -> void:
	# Dash lebih tinggi prioritas
	if _dash_cooldown_timer > 0.0:
		_dash_cooldown_timer -= delta
	if Input.is_action_just_pressed("dodge") and is_dash_ready():
		_start_dash()
	
	if _is_dashing:
		_update_dash(delta)
	else:
		_apply_gravity(delta)
		_handle_jump()
		_handle_movement(delta)
		if Input.is_action_just_pressed("attack"):
			_try_attack()
	
	move_and_slide()
	_check_fall_out()

func _start_dash() -> void:
	# Arah dash: ikuti input, kalau tidak ada input pakai arah hadap badan
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3.ZERO
	if input_dir.length() > 0.01:
		var camera_basis := _camera_pivot.global_transform.basis
		var forward := -camera_basis.z
		var right := camera_basis.x
		forward.y = 0
		right.y = 0
		forward = forward.normalized()
		right = right.normalized()
		direction = (right * input_dir.x - forward * input_dir.y).normalized()
	else:
		direction = Vector3(sin(_mesh_root.rotation.y), 0, cos(_mesh_root.rotation.y)).normalized()
	
	_dash_direction = direction
	_is_dashing = true
	_dash_timer = dash_duration
	_dash_cooldown_timer = dash_cooldown * GameManager.stats.dash_cooldown_mult
	GameManager.set_invulnerable(dash_invuln_time)
	_play_anim("Roll")
	# Hadapkan ke arah dash
	_mesh_root.rotation.y = atan2(direction.x, direction.z)

func _update_dash(delta: float) -> void:
	_dash_timer -= delta
	velocity.x = _dash_direction.x * dash_speed
	velocity.z = _dash_direction.z * dash_speed
	# Gravity tetap berlaku
	if not is_on_floor():
		velocity.y -= gravity * delta
	if _dash_timer <= 0.0:
		_is_dashing = false
		velocity.x = 0.0
		velocity.z = 0.0

func _play_anim(anim_name: String) -> void:
	if _anim == null:
		return
	if _current_anim == anim_name and _anim.is_playing():
		return
	_current_anim = anim_name
	if _anim.has_animation(anim_name):
		_anim.play(anim_name)

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
		if not _is_attacking:
			_play_anim("Idle")
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
	var target_velocity := direction * speed * GameManager.stats.bonus_speed_mult

	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)

	_face_direction(direction, delta)
	if not _is_attacking:
		_play_anim("Run")

func _decelerate(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	velocity.z = move_toward(velocity.z, 0.0, friction * delta)

func _face_direction(direction: Vector3, delta: float) -> void:
	if direction.length() < 0.01:
		return
	var target_angle := atan2(direction.x, direction.z)
	_mesh_root.rotation.y = lerp_angle(_mesh_root.rotation.y, target_angle, rotation_speed * delta)

func _try_attack() -> void:
	if _last_attack_time + attack_cooldown > _now():
		return  # cooldown aktif
	_last_attack_time = _now()
	_is_attacking = true
	_do_attack()

func _do_attack() -> void:
	var cam_forward := -_camera_pivot.global_transform.basis.z
	cam_forward.y = 0
	cam_forward = cam_forward.normalized()
	
	var target_angle := atan2(cam_forward.x, cam_forward.z)
	_mesh_root.rotation.y = target_angle
	
	if _anim:
		_play_anim("Sword_Attack")
	
	var attack_center := global_position + cam_forward * (attack_range * 0.5) + Vector3(0, 1, 0)
	var enemies := get_tree().get_nodes_in_group("enemies")
	var hit_enemies: Array = []
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var enemy_3d := enemy as Node3D
		if enemy_3d == null:
			continue
		var to_enemy: Vector3 = enemy_3d.global_position - global_position
		to_enemy.y = 0
		var dist: float = to_enemy.length()
		if dist > attack_range:
			continue
		var dot: float = to_enemy.normalized().dot(cam_forward)
		if dot < 0.3:
			continue
		if enemy.has_method("take_damage"):
			var dmg_roll := GameManager.stats.roll_damage(GameManager.player_current_health, GameManager.stats.max_health())
			enemy.take_damage(int(dmg_roll.damage))
			GameManager.apply_lifesteal(dmg_roll.damage)
			hit_enemies.append(enemy_3d)
		elif enemy.has_method("die"):
			enemy.die()
			hit_enemies.append(enemy_3d)
	
	if GameManager.stats.cleave_radius > 0.0 and hit_enemies.size() > 0:
		_apply_cleave(attack_center, hit_enemies)
	
	if GameManager.stats.projectile_enabled:
		_spawn_projectile(attack_center, cam_forward)

func _on_anim_finished(anim_name: String) -> void:
	if anim_name == "Sword_Attack":
		_is_attacking = false

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0

func _apply_cleave(center: Vector3, hit_enemies: Array) -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var enemy_3d := enemy as Node3D
		if enemy_3d == null:
			continue
		var to_enemy := enemy_3d.global_position - center
		to_enemy.y = 0
		if to_enemy.length() <= GameManager.stats.cleave_radius:
			var already_hit := false
			for h in hit_enemies:
				if h == enemy_3d:
					already_hit = true
					break
			if not already_hit:
				var dmg_roll := GameManager.stats.roll_damage(GameManager.player_current_health, GameManager.stats.max_health())
				enemy_3d.take_damage(int(dmg_roll.damage))

func _spawn_projectile(center: Vector3, direction: Vector3) -> void:
	var proj_scene := load("res://Scenes/Projectiles/blade_wave.tscn")
	if proj_scene == null:
		return
	var proj: Node = proj_scene.instantiate()
	if proj == null:
		return
	get_tree().root.add_child(proj)
	if proj is Node3D:
		proj.global_position = center
		proj.rotation.y = atan2(direction.x, direction.z)
	if proj.has_method("setup"):
		proj.setup(direction, GameManager.stats)
