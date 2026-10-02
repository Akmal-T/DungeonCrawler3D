extends Node3D
## World root — setup dungeon + player.

@onready var _dungeon_manager: Node3D = $DungeonManager
@onready var _player: CharacterBody3D = $Player

func _ready() -> void:
	_dungeon_manager.setup(_player)
