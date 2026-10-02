extends Node
## SoundManager singleton - manage SFX & music.

@export_category("Sound Settings")
@export var master_volume: float = 0.8
@export var sfx_volume: float = 1.0
@export var music_volume: float = 0.6

var _bus_master: int
var _bus_sfx: int
var _bus_music: int
var _ambience_player: AudioStreamPlayer = null
var _active_sfx: Dictionary = {}

func _ready() -> void:
	var audio_bus_idx = AudioServer.get_bus_index("Master")
	if audio_bus_idx != -1:
		_bus_master = audio_bus_idx
		AudioServer.set_bus_volume_db(_bus_master, linear_to_db(master_volume))
	
	_setup_audio_buses()
	
	GameManager.player_hit.connect(_play_sfx_hit_player)
	GameManager.enemy_hit.connect(_play_sfx_hit_enemy)
	GameManager.player_died.connect(_on_player_died)
	_play_ambience()

func _setup_audio_buses() -> void:
	_bus_sfx = AudioServer.get_bus_index("SFX")
	_bus_music = AudioServer.get_bus_index("Music")
	if _bus_sfx == -1:
		AudioServer.add_bus()
		_bus_sfx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(_bus_sfx, "SFX")
		AudioServer.set_bus_volume_db(_bus_sfx, linear_to_db(sfx_volume))
	if _bus_music == -1:
		AudioServer.add_bus()
		_bus_music = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(_bus_music, "Music")
		AudioServer.set_bus_volume_db(_bus_music, linear_to_db(music_volume))

func _play_sfx_hit_player() -> void:
	_play_sfx("res://Audio/SFX/player-hit_New.wav")

func _play_sfx_hit_enemy() -> void:
	_play_sfx("res://Audio/SFX/enemy-hit_New.wav")

func _on_player_died() -> void:
	_play_sfx("res://Audio/SFX/DeathSound.wav")

func _play_ambience() -> void:
	var stream = load("res://Audio/SFX/Ambience.wav")
	if stream == null:
		return
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Music"
	player.volume_db = linear_to_db(music_volume)
	add_child(player)
	player.play()
	_ambience_player = player

func _play_sfx(path: String, pitch_scale: float = 1.0) -> void:
	var sfx = load(path)
	if sfx == null:
		return
	
	# Skip kalau SFX yang sama masih playing (cegah overlap)
	var path_key = path
	if _active_sfx.has(path_key):
		var existing = _active_sfx[path_key]
		if is_instance_valid(existing) and existing.playing:
			return
	
	var player = AudioStreamPlayer.new()
	player.stream = sfx
	player.bus = "SFX"
	player.pitch_scale = pitch_scale
	add_child(player)
	player.play()
	player.finished.connect(_on_sfx_finished.bind(player, path_key))
	_active_sfx[path_key] = player

func _on_sfx_finished(player: AudioStreamPlayer, path_key: String) -> void:
	if _active_sfx.has(path_key) and _active_sfx[path_key] == player:
		_active_sfx.erase(path_key)
	if is_instance_valid(player):
		player.queue_free()

func set_master_volume(val: float) -> void:
	master_volume = val
	AudioServer.set_bus_volume_db(_bus_master, linear_to_db(val))

func set_sfx_volume(val: float) -> void:
	sfx_volume = val
	if _bus_sfx != -1:
		AudioServer.set_bus_volume_db(_bus_sfx, linear_to_db(val))

func set_music_volume(val: float) -> void:
	music_volume = val
	if _bus_music != -1:
		AudioServer.set_bus_volume_db(_bus_music, linear_to_db(val))
