extends Node3D

class_name AudioSystem

@export var master_volume: float = 1.0
@export var music_volume: float = 0.8
@export var sfx_volume: float = 1.0

var audio_players: Dictionary = {}
var current_music: AudioStreamPlayer = null

signal audio_played(sound_name: String)
signal music_changed(track_name: String)

func _ready() -> void:
	pass

func create_audio_player(name: String, sound_name: String) -> AudioStreamPlayer3D:
	if audio_players.has(name):
		return audio_players[name]

	var player = AudioStreamPlayer3D.new()
	player.name = name
	player.bus = "Master"
	add_child(player)

	audio_players[name] = player
	return player

func play_sound_at(sound_name: String, position: Vector3, volume: float = 1.0) -> void:
	var player = create_audio_player(sound_name + "_" + str(randi()), sound_name)
	player.global_position = position
	player.volume_db = linear2db(sfx_volume * volume * master_volume)

	await get_tree().create_timer(2.0).timeout
	player.queue_free()

	audio_played.emit(sound_name)

func play_ambient_sound(sound_name: String, looping: bool = true) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.name = "ambient_" + sound_name
	player.bus = "Master"
	player.volume_db = linear2db(sfx_volume * 0.6 * master_volume)

	add_child(player)

	if looping:
		player.stream.loop = true

	return player

func play_music(track_name: String, fade_in: bool = true) -> void:
	if current_music:
		if fade_in:
			var tween = create_tween()
			tween.tween_property(current_music, "volume_db", -80, 1.0)
			await tween.finished
		current_music.stop()
		current_music.queue_free()

	current_music = AudioStreamPlayer.new()
	current_music.name = "music_" + track_name
	current_music.bus = "Master"
	current_music.volume_db = linear2db(music_volume * master_volume)

	add_child(current_music)

	if fade_in:
		current_music.volume_db = -80
		var tween = create_tween()
		tween.tween_property(current_music, "volume_db", linear2db(music_volume * master_volume), 2.0)

	music_changed.emit(track_name)

func stop_music(fade_out: bool = true) -> void:
	if not current_music:
		return

	if fade_out:
		var tween = create_tween()
		tween.tween_property(current_music, "volume_db", -80, 1.0)
		await tween.finished

	current_music.stop()
	current_music.queue_free()
	current_music = null

func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), master_volume == 0.0)

func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	if current_music:
		current_music.volume_db = linear2db(music_volume * master_volume)

func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)

func get_master_volume() -> float:
	return master_volume

func get_music_volume() -> float:
	return music_volume

func get_sfx_volume() -> float:
	return sfx_volume
