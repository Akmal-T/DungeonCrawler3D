extends CanvasLayer

@onready var _level_reached_label: Label = $CenterContainer/VBoxContainer/LevelReachedLabel
@onready var _restart_button: Button = $CenterContainer/VBoxContainer/RestartButton

func _ready() -> void:
	GameManager.player_died.connect(_on_player_died)
	_restart_button.pressed.connect(_on_restart_pressed)
	visible = false

func _on_player_died() -> void:
	_level_reached_label.text = "Level Reached: %d" % GameManager.current_level
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_restart_pressed() -> void:
	get_tree().paused = false
	GameManager.reset_game()
	get_tree().reload_current_scene()
