extends Area3D
## Upgrade pickup: collect to apply buff.

@export var upgrade_type: String = "health_potion"
@export var value: int = 20

var _player: CharacterBody3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_apply_visual()

func _apply_visual() -> void:
	match upgrade_type:
		"health_potion":
			var mesh = CSGSphere3D.new()
			mesh.radius = 0.4
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(1, 0.3, 0.3)
			mat.emission_enabled = true
			mat.emission = Color(1, 0.1, 0.1)
			mesh.material = mat
			add_child(mesh)
		"speed_boost":
			var mesh = CSGSphere3D.new()
			mesh.radius = 0.4
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.3, 1, 0.3)
			mat.emission_enabled = true
			mat.emission = Color(0.1, 1, 0.1)
			mesh.material = mat
			add_child(mesh)
		"damage_boost":
			var mesh = CSGSphere3D.new()
			mesh.radius = 0.4
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(1, 0.8, 0.2)
			mat.emission_enabled = true
			mat.emission = Color(1, 0.6, 0.1)
			mesh.material = mat
			add_child(mesh)
		"max_health":
			var mesh = CSGSphere3D.new()
			mesh.radius = 0.4
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.3, 0.3, 1)
			mat.emission_enabled = true
			mat.emission = Color(0.1, 0.1, 1)
			mesh.material = mat
			add_child(mesh)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.name == "Player":
		_apply_upgrade()
		queue_free()

func _apply_upgrade() -> void:
	match upgrade_type:
		"health_potion":
			GameManager.heal_player(value)
		"speed_boost":
			GameManager.player_speed_multiplier = min(GameManager.player_speed_multiplier + 0.1, 2.0)
		"damage_boost":
			GameManager.player_damage += value * 0.5
		"max_health":
			GameManager.player_max_health += value
			GameManager.heal_player(value)
	GameManager.add_upgrade(upgrade_type)
