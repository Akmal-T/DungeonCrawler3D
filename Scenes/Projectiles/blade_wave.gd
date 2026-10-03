extends Area3D
## Blade Wave: proyektil dari upgrade "Blade Wave".
## Melaju lurus, menembus musuh (piercing), memberi damage, lalu hilang setelah lifetime.

@export var speed: float = 14.0
@export var lifetime: float = 1.2
@export var hit_radius: float = 1.2

var _direction: Vector3 = Vector3.FORWARD
var _damage_mult: float = 0.5
var _stats = null
var _life: float = 0.0
var _hit_this_frame: Array = []

func setup(direction: Vector3, stats) -> void:
	_direction = direction.normalized()
	_stats = stats
	if stats:
		_damage_mult = stats.projectile_damage_mult

func _ready() -> void:
	monitoring = false
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	life_tick(delta)

func life_tick(delta: float) -> void:
	_life += delta
	global_position += _direction * speed * delta
	if _life >= lifetime:
		queue_free()
		return
	_check_hits()

func _check_hits() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var enemy_3d := enemy as Node3D
		if enemy_3d == null:
			continue
		if _hit_this_frame.has(enemy_3d):
			continue
		var to_enemy := enemy_3d.global_position - global_position
		to_enemy.y = 0
		if to_enemy.length() <= hit_radius:
			_hit_this_frame.append(enemy_3d)
			if enemy_3d.has_method("take_damage"):
				var base_dmg: float = 10.0
				if _stats:
					base_dmg = _stats.damage(GameManager.player_current_health, _stats.max_health())
				enemy_3d.take_damage(int(base_dmg * _damage_mult))

func _on_body_entered(_body: Node3D) -> void:
	queue_free()
