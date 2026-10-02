extends CanvasLayer

@onready var _level_label: Label = $MarginContainer/VBoxContainer/LevelLabel
@onready var _score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var _health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var _dash_bar: ProgressBar = $MarginContainer/VBoxContainer/DashBar

var _player: CharacterBody3D = null

func _ready() -> void:
	GameManager.level_changed.connect(_on_level_changed)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.health_changed.connect(_on_health_changed)
	_update_ui()
	_find_player.call_deferred()

func _find_player() -> void:
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player")

func _process(_delta: float) -> void:
	if _player and _player.has_method("get_dash_cooldown_ratio"):
		var ratio: float = _player.get_dash_cooldown_ratio()
		_dash_bar.value = 1.0 - ratio

func _update_ui() -> void:
	_level_label.text = "Level: %d" % GameManager.current_level
	_score_label.text = "Score: %d" % GameManager.score
	_health_bar.max_value = GameManager.get_player_max_health()
	_health_bar.value = GameManager.player_current_health

func _on_level_changed(_level: int) -> void:
	_level_label.text = "Level: %d" % _level

func _on_score_changed(score: int) -> void:
	_score_label.text = "Score: %d" % score

func _on_health_changed(current: int, maximum: int) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current
