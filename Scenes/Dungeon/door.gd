extends Area3D
## Door trigger. Bedakan pintu biasa (explore) dan pintu exit (next level).

signal player_entered(door: Area3D)

@export var direction: String = ""        # "north", "south", "east", "west"
@export var is_exit: bool = false         # true = pintu keluar (next level)
@export var target_cell: Vector2i = Vector2i.ZERO  # ruangan tujuan (untuk pintu biasa)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	set_monitorable(true)
	set_monitoring(true)
	if is_exit:
		_add_exit_marker()

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		player_entered.emit(self)

func _add_exit_marker() -> void:
	# Penanda visual: gelang merah menyala di depan pintu exit
	var marker := OmniLight3D.new()
	marker.light_color = Color(1, 0.15, 0.15)
	marker.light_energy = 3.0
	marker.omni_range = 8.0
	marker.position = Vector3(0, 2, 0)
	add_child(marker)

	# Gate mesh berpendar sebagai penanda pintu keluar
	var gate_scene = load("res://Assets/Kenney_MiniDungeon/Models/GLB format/gate.glb")
	if gate_scene:
		var gate = gate_scene.instantiate()
		gate.position = Vector3(0, 0, 0)
		# Rotasi gate menghadap ke dalam ruangan sesuai arah
		match direction:
			"north": gate.rotation.y = 0.0
			"south": gate.rotation.y = PI
			"east": gate.rotation.y = -PI / 2.0
			"west": gate.rotation.y = PI / 2.0
		add_child(gate)
