extends Node3D
## Third-person orbit camera (Zelda style).
## Attach ke CameraPivot. Camera3D jadi child di dalamnya.

@export var mouse_sensitivity: float = 0.003
@export var follow_speed: float = 10.0
@export var min_pitch: float = deg_to_rad(-60.0)
@export var max_pitch: float = deg_to_rad(30.0)
@export var zoom_step: float = 0.5
@export var min_zoom: float = 2.0
@export var max_zoom: float = 8.0
@export var base_distance: float = 5.0
@export var camera_height: float = 1.5

@onready var _camera: Camera3D = $Camera3D

var _target_yaw: float = 0.0
var _target_pitch: float = deg_to_rad(-20.0)
var _current_distance: float = 5.0
var _shake_amount: float = 0.0
var _shake_decay: float = 6.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_current_distance = base_distance
	GameManager.player_hit.connect(_on_player_hit)
	GameManager.enemy_hit.connect(_on_enemy_hit)

func _on_player_hit() -> void:
	shake(0.35)

func _on_enemy_hit() -> void:
	shake(0.12)

func shake(amount: float) -> void:
	_shake_amount = max(_shake_amount, amount)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_target_yaw -= event.relative.x * mouse_sensitivity
		_target_pitch = clamp(
			_target_pitch - event.relative.y * mouse_sensitivity,
			min_pitch, max_pitch
		)
	elif event.is_action_pressed("camera_zoom_in"):
		_current_distance = clamp(_current_distance - zoom_step, min_zoom, max_zoom)
	elif event.is_action_pressed("camera_zoom_out"):
		_current_distance = clamp(_current_distance + zoom_step, min_zoom, max_zoom)
	elif event.is_action_pressed("pause"):
		_toggle_mouse_capture()

func _toggle_mouse_capture() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	rotation.y = lerp_angle(rotation.y, _target_yaw, follow_speed * delta)
	rotation.x = lerp_angle(rotation.x, _target_pitch, follow_speed * delta)

	if is_instance_valid(_camera):
		var shake_offset := Vector3.ZERO
		if _shake_amount > 0.01:
			shake_offset = Vector3(
				randf_range(-1.0, 1.0),
				randf_range(-1.0, 1.0),
				randf_range(-1.0, 1.0)
			) * _shake_amount
			_shake_amount = lerp(_shake_amount, 0.0, _shake_decay * delta)
		_camera.position = Vector3(0, camera_height, _current_distance) + shake_offset
