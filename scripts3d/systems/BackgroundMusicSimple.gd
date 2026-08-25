extends BaseSystemSimple

class_name BackgroundMusicSimple

class Track:
	var id: String
	var name: String
	var category: String
	var volume: float
	var looping: bool
	func _init(p_id: String, p_name: String, p_cat: String, p_vol: float = 0.8) -> void:
		id = p_id
		name = p_name
		category = p_cat
		volume = p_vol
		looping = true

var tracks: Dictionary = {}

signal track_changed(track: Track)
signal music_started(track_id: String)
signal music_stopped
signal fade_complete

func _ready() -> void:
	set_state("current_track", "")
	set_state("current_volume", 1.0)
	set_state("track_history", [])
	set_state("track_transitions", [])
	set_state("mood_state", "neutral")
	set_state("track_replay_count", {})
	set_state("fade_history", [])
	set_state("music_preferences", {})
	set_state("crossfade_effects", [])
	set_state("track_play_history", [])
	set_state("track_stop_history", [])
	set_state("music_statistics", {})
	_initialize_tracks()

func _initialize_tracks() -> void:
	tracks = {
		"ambient_forest": Track.new("ambient_forest", "Forest Ambience", "ambient", 0.6),
		"explore_theme": Track.new("explore_theme", "Exploration Theme", "exploration", 0.7),
		"battle_theme": Track.new("battle_theme", "Battle Theme", "battle", 0.8),
		"boss_theme": Track.new("boss_theme", "Boss Battle", "boss", 0.9),
		"calm_rest": Track.new("calm_rest", "Rest Area", "calm", 0.5),
		"tavern_music": Track.new("tavern_music", "Tavern Music", "social", 0.7),
		"victory": Track.new("victory", "Victory Fanfare", "victory", 0.8),
		"defeat": Track.new("defeat", "Defeat Theme", "defeat", 0.8)
	}

func _record_track_play(track_id: String, category: String) -> void:
	var history = get_state("track_play_history", [])
	history.append({"track_id": track_id, "category": category, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("track_play_history", history)

func _record_track_stop(track_id: String) -> void:
	var history = get_state("track_stop_history", [])
	history.append({"track_id": track_id, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("track_stop_history", history)

func play_track(track_id: String) -> bool:
	if track_id in tracks:
		var track = tracks[track_id]
		set_state("current_track", track_id)
		_record_track_play(track_id, track.category)
		increment_replay_count(track_id)
		music_started.emit(track_id)
		track_changed.emit(track)
		emit_event("track_changed", track_id)
		return true
	return false

func stop_music() -> void:
	var current = get_state("current_track", "")
	if current != "":
		_record_track_stop(current)
	set_state("current_track", "")
	music_stopped.emit()
	emit_event("music_stopped", "")

func fade_to_track(track_id: String, fade_duration: float = 1.0) -> void:
	if track_id in tracks:
		await get_tree().create_timer(fade_duration).timeout
		play_track(track_id)
		fade_complete.emit()
		emit_event("fade_complete", track_id)

func set_track_volume(track_id: String, volume: float) -> void:
	if track_id in tracks:
		tracks[track_id].volume = clampf(volume, 0.0, 1.0)
		emit_event("volume_changed", track_id)

func get_track(track_id: String) -> Track:
	return tracks.get(track_id, null)

func get_current_track() -> Track:
	var track_id = get_state("current_track", "")
	return get_track(track_id) if track_id != "" else null

func get_tracks_by_category(category: String) -> Array[Track]:
	var result: Array[Track] = []
	for track in tracks.values():
		if track.category == category:
			result.append(track)
	return result

func get_music_text() -> String:
	var current = get_current_track()
	if current:
		return "Now Playing: %s\nVolume: %.0f%%" % [current.name, current.volume * 100.0]
	return "No music playing"

func record_track_history(track_id: String, duration_ms: int) -> void:
	var history = get_state("track_history", [])
	history.append({"track": track_id, "duration": duration_ms, "time": Time.get_ticks_msec()})
	if history.size() > 100:
		history.pop_front()
	set_state("track_history", history)

func record_transition(from_track: String, to_track: String, transition_time: float) -> void:
	var transitions = get_state("track_transitions", [])
	transitions.append({"from": from_track, "to": to_track, "time": transition_time, "timestamp": Time.get_ticks_msec()})
	if transitions.size() > 50:
		transitions.pop_front()
	set_state("track_transitions", transitions)

func set_mood(mood: String) -> void:
	set_state("mood_state", mood)
	emit_event("mood_changed", mood)

func increment_replay_count(track_id: String) -> void:
	var replays = get_state("track_replay_count", {})
	replays[track_id] = replays.get(track_id, 0) + 1
	set_state("track_replay_count", replays)

func get_replay_count(track_id: String) -> int:
	var replays = get_state("track_replay_count", {})
	return replays.get(track_id, 0)

func record_fade_effect(from_volume: float, to_volume: float, duration: float) -> void:
	var fades = get_state("fade_history", [])
	fades.append({"from": from_volume, "to": to_volume, "duration": duration, "time": Time.get_ticks_msec()})
	if fades.size() > 50:
		fades.pop_front()
	set_state("fade_history", fades)

func set_track_preference(track_id: String, preference: float) -> void:
	var prefs = get_state("music_preferences", {})
	prefs[track_id] = clampf(preference, 0.0, 1.0)
	set_state("music_preferences", prefs)

func get_track_preference(track_id: String) -> float:
	var prefs = get_state("music_preferences", {})
	return prefs.get(track_id, 0.5)

func record_crossfade(track1: String, track2: String) -> void:
	var crossfades = get_state("crossfade_effects", [])
	crossfades.append({"track1": track1, "track2": track2, "time": Time.get_ticks_msec()})
	if crossfades.size() > 30:
		crossfades.pop_front()
	set_state("crossfade_effects", crossfades)

func get_most_played_track() -> String:
	var replays = get_state("track_replay_count", {})
	if replays.is_empty():
		return ""
	var max_track = ""
	var max_count = 0
	for track_id in replays:
		if replays[track_id] > max_count:
			max_count = replays[track_id]
			max_track = track_id
	return max_track

func get_mood() -> String:
	return get_state("mood_state", "neutral")

func update_music_statistics() -> void:
	var stats = get_state("music_statistics", {})
	var play_hist = get_state("track_play_history", [])
	var stop_hist = get_state("track_stop_history", [])
	var transitions = get_state("track_transitions", [])
	var fades = get_state("fade_history", [])
	var replays = get_state("track_replay_count", {})
	stats["tracks_played"] = play_hist.size()
	stats["tracks_stopped"] = stop_hist.size()
	var unique_tracks = {}
	for entry in play_hist:
		unique_tracks[entry["track_id"]] = true
	stats["unique_tracks_played"] = unique_tracks.size()
	stats["total_transitions"] = transitions.size()
	stats["total_fades"] = fades.size()
	stats["most_played"] = get_most_played_track()
	stats["current_track"] = get_state("current_track", "")
	stats["current_mood"] = get_state("mood_state", "neutral")
	stats["current_volume"] = get_state("current_volume", 1.0)
	var prefs = get_state("music_preferences", {})
	stats["preferences_set"] = prefs.size()
	set_state("music_statistics", stats)

func get_music_statistics() -> Dictionary:
	update_music_statistics()
	return get_state("music_statistics", {})
