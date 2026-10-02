extends CanvasLayer

@onready var _level_label: Label = $MarginContainer/VBoxContainer/LevelLabel
@onready var _score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var _health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar

func _ready() -> void:
	GameManager.level_changed.connect(_on_level_changed)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.health_changed.connect(_on_health_changed)
	_update_ui()

func _update_ui() -> void:
	_level_label.text = "Level: %d" % GameManager.current_level
	_score_label.text = "Score: %d" % GameManager.score
	_health_bar.max_value = GameManager.player_max_health
	_health_bar.value = GameManager.player_current_health

func _on_level_changed(_level: int) -> void:
	_level_label.text = "Level: %d" % _level

func _on_score_changed(score: int) -> void:
	_score_label.text = "Score: %d" % score

func _on_health_changed(current: int, maximum: int) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current
