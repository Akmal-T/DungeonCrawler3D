extends CanvasLayer
## Upgrade Selection: tampil saat naik level, pilih 1 dari 3 upgrade.

@onready var _title: Label = $Panel/VBox/Title
@onready var _btn1: Button = $Panel/VBox/Option1
@onready var _btn2: Button = $Panel/VBox/Option2
@onready var _btn3: Button = $Panel/VBox/Option3

var _choices: Array = []

func _ready() -> void:
	visible = false
	GameManager.level_completed.connect(_on_level_completed)
	_btn1.pressed.connect(_on_btn1_pressed)
	_btn2.pressed.connect(_on_btn2_pressed)
	_btn3.pressed.connect(_on_btn3_pressed)

func _on_level_completed() -> void:
	_show_selection()

func _show_selection() -> void:
	_choices = UpgradePool.get_random_choices(3, GameManager.upgrades_taken)
	if _choices.size() == 0:
		return
	
	# Fill button text
	_btn1.text = ""
	_btn2.text = ""
	_btn3.text = ""
	_btn1.visible = false
	_btn2.visible = false
	_btn3.visible = false
	
	if _choices.size() >= 1:
		var upg = _choices[0]
		_btn1.text = "%s\n%s" % [upg.name, upg.description]
		_btn1.visible = true
	if _choices.size() >= 2:
		var upg = _choices[1]
		_btn2.text = "%s\n%s" % [upg.name, upg.description]
		_btn2.visible = true
	if _choices.size() >= 3:
		var upg = _choices[2]
		_btn3.text = "%s\n%s" % [upg.name, upg.description]
		_btn3.visible = true
	
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_btn1_pressed() -> void:
	_select_upgrade(0)

func _on_btn2_pressed() -> void:
	_select_upgrade(1)

func _on_btn3_pressed() -> void:
	_select_upgrade(2)

func _select_upgrade(index: int) -> void:
	if index >= _choices.size():
		return
	var upg = _choices[index]
	GameManager.apply_upgrade(upg)
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
