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

func play_track(track_id: String) -> bool:
	if track_id in tracks:
		var track = tracks[track_id]
		set_state("current_track", track_id)
		music_started.emit(track_id)
		track_changed.emit(track)
		emit_event("track_changed", track_id)
		return true
	return false

func stop_music() -> void:
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
