extends CharacterBody3D
## Enemy AI: chase player, contact damage, HP system dengan hit feedback.

@export var speed: float = 3.0
@export var damage: int = 10
@export var detection_range: float = 15.0
@export var attack_range: float = 1.5
@export var attack_delay: float = 0.5
@export var max_health: int = 30
@export var score_value: int = 10

@onready var _mesh_root: Node3D = $MeshRoot

var _player: CharacterBody3D = null
var _anim: AnimationPlayer = null
var _last_attack_time: float = 0.0
var _current_health: int = 30
var _is_dying: bool = false
var _hit_flash_time: float = 0.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

func _ready() -> void:
	_current_health = max_health
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		_player = get_tree().root.find_child("Player", true, false)
	if _player == null:
		print("ERROR: Enemy cannot find Player")
		queue_free()
		return
	# Ambil AnimationPlayer dari model (kalau ada)
	for child in _mesh_root.get_children():
		var ap = child.find_child("AnimationPlayer", true, false)
		if ap:
			_anim = ap
			break
	if _anim and _anim.has_animation("Idle"):
		_anim.play("Idle")

func _physics_process(delta: float) -> void:
	if _is_dying:
		return
	if _player == null or not is_instance_valid(_player):
		return

	_apply_gravity(delta)
	_chase_player(delta)
	_check_attack(delta)
	move_and_slide()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

func _chase_player(delta: float) -> void:
	var dir_to_player := _player.global_position - global_position
	dir_to_player.y = 0
	var dist := dir_to_player.length()

	if dist > detection_range or dist <= attack_range:
		velocity.x = 0.0
		velocity.z = 0.0
		_play_anim("Idle")
		return

	dir_to_player = dir_to_player.normalized()
	var target_velocity := dir_to_player * speed
	velocity.x = target_velocity.x
	velocity.z = target_velocity.z

	# Hadapkan model ke arah pemain
	if _mesh_root:
		var target_angle := atan2(dir_to_player.x, dir_to_player.z)
		_mesh_root.rotation.y = lerp_angle(_mesh_root.rotation.y, target_angle, 10.0 * delta)
	_play_anim("Walk")

func _check_attack(delta: float) -> void:
	var dist_to_player := (global_position - _player.global_position).length()
	if dist_to_player <= attack_range and _last_attack_time + attack_delay < _now():
		_last_attack_time = _now()
		_attack_player()

func _attack_player() -> void:
	GameManager.damage_player(damage)
	if _anim and _anim.has_animation("Bite_Front"):
		_anim.play("Bite_Front")
	if _anim:
		_anim.queue("Idle")

## Dipanggil player saat menyerang.
func take_damage(amount: int) -> void:
	if _is_dying:
		return
	_current_health -= amount
	GameManager.enemy_hit.emit()
	_flash_hit()
	if _anim and _anim.has_animation("HitRecieve"):
		_anim.play("HitRecieve")
		_anim.queue("Idle")
	if _current_health <= 0:
		die()

func die() -> void:
	if _is_dying:
		return
	_is_dying = true
	velocity = Vector3.ZERO
	GameManager.score += score_value
	GameManager.score_changed.emit(GameManager.score)
	_drop_upgrade()

	if _anim and _anim.has_animation("Death"):
		_anim.play("Death")
		_anim.animation_finished.connect(_on_death_anim_finished, CONNECT_ONE_SHOT)
		# Matikan collision biar player bisa lewat
		var col = get_node_or_null("CollisionShape3D")
		if col:
			col.disabled = true
	else:
		queue_free()

func _on_death_anim_finished(_name: String) -> void:
	queue_free()

func _play_anim(name: String) -> void:
	if _anim == null:
		return
	if not _anim.has_animation(name):
		return
	var current = _anim.get_current_animation()
	if current == name and _anim.is_playing():
		return
	_anim.play(name)

func _flash_hit() -> void:
	# Efek kedip cepat: perbesar sedikit mesh sebagai feedback
	if _mesh_root == null:
		return
	var tween := create_tween()
	tween.tween_property(_mesh_root, "scale", Vector3(1.2, 0.8, 1.2), 0.05)
	tween.tween_property(_mesh_root, "scale", Vector3.ONE, 0.1)

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0

func _drop_upgrade() -> void:
	var upgrade_scene = load("res://Scenes/Upgrades/upgrade_pickup.tscn")
	if upgrade_scene:
		var pickup = upgrade_scene.instantiate()
		pickup.position = global_position
		pickup.upgrade_type = "health_potion"
		get_parent().add_child(pickup)
