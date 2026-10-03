extends Area3D
## Upgrade pickup: collect to apply buff.

@export var upgrade_type: String = "health_potion"
@export var value: int = 20
@export var pickup_scale: float = 0.8

var _visual: Node3D = null
var _bob_time: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_apply_visual()

func _process(delta: float) -> void:
	_bob_time += delta
	if _visual:
		_visual.rotation.y += delta * 1.5
		var base_y := 0.6
		_visual.position.y = base_y + sin(_bob_time * 2.5) * 0.15

func _apply_visual() -> void:
	var path = ""
	match upgrade_type:
		"health_potion":
			path = "res://Assets/Kenney_MiniDungeon/Models/GLB format/potion.glb"
		"speed_boost":
			path = "res://Assets/Kenney_MiniDungeon/Models/GLB format/key.glb"
		"damage_boost":
			path = "res://Assets/Kenney_MiniDungeon/Models/GLB format/coin.glb"
		"max_health":
			path = "res://Assets/Kenney_MiniDungeon/Models/GLB format/chest.glb"
	if path == "":
		return
	var scene = load(path)
	if scene == null:
		return
	var mesh = scene.instantiate()
	mesh.scale = Vector3(pickup_scale, pickup_scale, pickup_scale)
	mesh.position.y = 0.6
	add_child(mesh)
	_visual = mesh

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.name == "Player":
		_apply_upgrade()
		queue_free()

func _apply_upgrade() -> void:
	match upgrade_type:
		"health_potion":
			GameManager.heal_player(value)
		"speed_boost":
			GameManager.stats.bonus_speed_mult += 0.1
		"damage_boost":
			GameManager.stats.bonus_damage += value * 0.5
		"max_health":
			GameManager.stats.bonus_max_health += value
			GameManager.heal_player(value)
