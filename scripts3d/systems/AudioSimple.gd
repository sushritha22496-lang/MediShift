extends Node

class_name AudioSimple

var music_player: AudioStreamPlayer = null
var sfx_players: Array[AudioStreamPlayer3D] = []
var music_volume: float = 0.7
var sfx_volume: float = 0.8

var audio_history: Array = []
var volume_profiles: Dictionary = {}
var audio_queue: Array = []
var spatial_audio_positions: Dictionary = {}
var fade_effects: Dictionary = {}
var audio_metrics: Dictionary = {"tracks_played": 0, "total_duration": 0.0}
var mute_state: Dictionary = {"music": false, "sfx": false}
var audio_performance: Array = []
var music_play_history: Array = []
var sfx_play_history: Array = []
var volume_change_history: Array = []
var audio_statistics: Dictionary = {}

signal music_started(track: String)
signal sfx_played(sound: String)
signal audio_queued(sound: String)
signal volume_changed(type: String)

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

func _record_music_play(track_path: String) -> void:
	music_play_history.append({"track": track_path, "time": Time.get_ticks_msec()})
	if music_play_history.size() > 50:
		music_play_history.pop_front()

func _record_sfx_play(sound_path: String, position: Vector3) -> void:
	sfx_play_history.append({"sound": sound_path, "position": position, "time": Time.get_ticks_msec()})
	if sfx_play_history.size() > 50:
		sfx_play_history.pop_front()

func _record_volume_change(audio_type: String, new_volume: float) -> void:
	volume_change_history.append({"type": audio_type, "volume": new_volume, "time": Time.get_ticks_msec()})
	if volume_change_history.size() > 50:
		volume_change_history.pop_front()

func play_music(track_path: String, loop: bool = true) -> void:
	if ResourceLoader.exists(track_path):
		var audio = load(track_path)
		music_player.stream = audio
		music_player.stream.loop = loop
		music_player.play()
		_record_music_play(track_path)
		increment_tracks_played()
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
	_record_sfx_play(sound_path, position)
	increment_tracks_played()
	sfx_played.emit(sound_path)

func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	music_player.volume_db = linear2db(music_volume)
	_record_volume_change("music", music_volume)

func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	for sfx in sfx_players:
		sfx.volume_db = linear2db(sfx_volume)
	_record_volume_change("sfx", sfx_volume)

func get_music_volume() -> float:
	return music_volume

func get_sfx_volume() -> float:
	return sfx_volume

func record_audio_history(track: String, audio_type: String, duration: float) -> void:
	audio_history.append({"track": track, "type": audio_type, "duration": duration, "time": Time.get_ticks_msec()})
	if audio_history.size() > 50:
		audio_history.pop_front()

func save_volume_profile(profile_name: String) -> void:
	volume_profiles[profile_name] = {"music": music_volume, "sfx": sfx_volume}

func load_volume_profile(profile_name: String) -> bool:
	if profile_name in volume_profiles:
		music_volume = volume_profiles[profile_name]["music"]
		sfx_volume = volume_profiles[profile_name]["sfx"]
		music_player.volume_db = linear2db(music_volume)
		for sfx in sfx_players:
			sfx.volume_db = linear2db(sfx_volume)
		volume_changed.emit("profile")
		return true
	return false

func queue_audio(sound_path: String, priority: int = 0) -> void:
	audio_queue.append({"path": sound_path, "priority": priority})
	audio_queue.sort_custom(func(a, b): return a["priority"] > b["priority"])
	audio_queued.emit(sound_path)

func get_queued_audio() -> Array:
	return audio_queue

func record_spatial_audio(sound_id: String, position: Vector3) -> void:
	spatial_audio_positions[sound_id] = position

func apply_fade_effect(player: AudioStreamPlayer, duration: float, target_volume: float) -> void:
	var tween = create_tween()
	tween.tween_property(player, "volume_db", linear2db(target_volume), duration)
	fade_effects[player] = {"duration": duration, "target": target_volume}

func set_mute(audio_type: String, muted: bool) -> void:
	mute_state[audio_type] = muted
	if audio_type == "music":
		music_player.volume_db = -80.0 if muted else linear2db(music_volume)
	elif audio_type == "sfx":
		for sfx in sfx_players:
			sfx.volume_db = -80.0 if muted else linear2db(sfx_volume)
	emit_event("mute_changed", audio_type)

func is_muted(audio_type: String) -> bool:
	return mute_state.get(audio_type, false)

func record_audio_performance(fps: float, latency_ms: int) -> void:
	audio_performance.append({"fps": fps, "latency": latency_ms, "time": Time.get_ticks_msec()})
	if audio_performance.size() > 100:
		audio_performance.pop_front()

func increment_tracks_played() -> void:
	audio_metrics["tracks_played"] += 1

func add_total_duration(duration: float) -> void:
	audio_metrics["total_duration"] += duration

func get_total_tracks_played() -> int:
	return audio_metrics.get("tracks_played", 0)

func get_total_audio_duration() -> float:
	return audio_metrics.get("total_duration", 0.0)

func get_audio_history() -> Array:
	return audio_history

func update_audio_statistics() -> void:
	audio_statistics["music_plays"] = music_play_history.size()
	audio_statistics["sfx_plays"] = sfx_play_history.size()
	audio_statistics["total_plays"] = audio_metrics["tracks_played"]
	audio_statistics["total_duration"] = audio_metrics["total_duration"]
	audio_statistics["volume_changes"] = volume_change_history.size()
	audio_statistics["current_music_volume"] = music_volume
	audio_statistics["current_sfx_volume"] = sfx_volume
	audio_statistics["music_muted"] = mute_state.get("music", false)
	audio_statistics["sfx_muted"] = mute_state.get("sfx", false)
	audio_statistics["audio_queue_size"] = audio_queue.size()
	audio_statistics["volume_profiles_saved"] = volume_profiles.size()
	audio_statistics["audio_history_size"] = audio_history.size()

func get_audio_statistics() -> Dictionary:
	update_audio_statistics()
	return audio_statistics
