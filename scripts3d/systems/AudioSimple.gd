extends Node

class_name AudioSimple

var music_player: AudioStreamPlayer = null
var sfx_players: Array[AudioStreamPlayer3D] = []
var music_volume: float = 0.7
var sfx_volume: float = 0.8

signal music_started(track: String)
signal sfx_played(sound: String)

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)

	for i in range(5):
		var sfx = AudioStreamPlayer3D.new()
		sfx.bus = "Master"
		add_child(sfx)
		sfx_players.append(sfx)

	music_player.volume_db = linear2db(music_volume)

func play_music(track_path: String, loop: bool = true) -> void:
	if ResourceLoader.exists(track_path):
		var audio = load(track_path)
		music_player.stream = audio
		music_player.stream.loop = loop
		music_player.play()
		music_started.emit(track_path)

func stop_music() -> void:
	music_player.stop()

func play_sfx(sound_path: String, position: Vector3 = Vector3.ZERO) -> void:
	if not ResourceLoader.exists(sound_path):
		return

	var audio = load(sound_path)
	var available_player = null

	for sfx in sfx_players:
		if not sfx.playing:
			available_player = sfx
			break

	if available_player == null:
		available_player = sfx_players[0]

	available_player.stream = audio
	available_player.global_position = position
	available_player.volume_db = linear2db(sfx_volume)
	available_player.play()
	sfx_played.emit(sound_path)

func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	music_player.volume_db = linear2db(music_volume)

func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	for sfx in sfx_players:
		sfx.volume_db = linear2db(sfx_volume)

func get_music_volume() -> float:
	return music_volume

func get_sfx_volume() -> float:
	return sfx_volume
