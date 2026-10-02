extends CharacterBody3D
## Enemy AI: simple chase + contact damage.

@export var speed: float = 3.0
@export var damage: int = 10
@export var detection_range: float = 15.0
@export var attack_range: float = 1.5
@export var attack_delay: float = 0.5

@onready var _player: CharacterBody3D = null
@onready var _last_attack_time: float = 0.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

func _ready() -> void:
	# Cari player di scene tree
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		# Fallback: cari node bernama "Player"
		_player = get_tree().root.find_child("Player", true, false)
	if _player == null:
		print("ERROR: Enemy cannot find Player")
		queue_free()

func _physics_process(delta: float) -> void:
	if _player == null:
		queue_free()
		return
	
	_apply_gravity(delta)
	_chase_player(delta)
	_check_attack(delta)
	move_and_slide()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

func _chase_player(delta: float) -> void:
	if not is_instance_valid(_player):
		return
	
	var dir_to_player := _player.global_position - global_position
	dir_to_player.y = 0
	var dist := dir_to_player.length()
	
	if dist > detection_range:
		return  # di luar detection range
	
	# Move toward player
	dir_to_player = dir_to_player.normalized()
	var target_velocity := dir_to_player * speed
	velocity.x = target_velocity.x
	velocity.z = target_velocity.z

func _check_attack(delta: float) -> void:
	if not is_instance_valid(_player):
		return
	
	var dist_to_player := (global_position - _player.global_position).length()
	
	if dist_to_player <= attack_range and _last_attack_time + attack_delay < get_time():
		_attack_player()
		_last_attack_time = get_time()

func _attack_player() -> void:
	GameManager.damage_player(damage)
	# Hit feedback: screen shake atau particle (nanti ditambah)

func get_time() -> float:
	return Time.get_ticks_msec() / 1000.0

func die() -> void:
	# Drop upgrade (chest/coin/potion)
	_drop_upgrade()
	queue_free()

func _drop_upgrade() -> void:
	var upgrade_scene = load("res://Scenes/Upgrades/upgrade_pickup.tscn")
	if upgrade_scene:
		var pickup = upgrade_scene.instantiate()
		pickup.position = global_position
		pickup.upgrade_type = "health_potion"
		get_parent().add_child(pickup)
