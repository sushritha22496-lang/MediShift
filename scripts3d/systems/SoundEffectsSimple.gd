extends BaseSystemSimple

class_name SoundEffectsSimple

class SoundEffect:
	var id: String
	var name: String
	var volume: float
	var pitch: float
	func _init(p_id: String, p_name: String, p_vol: float = 1.0, p_pitch: float = 1.0) -> void:
		id = p_id
		name = p_name
		volume = p_vol
		pitch = p_pitch

var sound_effects: Dictionary = {}

signal sound_played(sound_id: String)
signal sound_stopped(sound_id: String)

func _ready() -> void:
	set_state("master_volume", 1.0)
	set_state("sfx_volume", 0.8)
	set_state("active_sounds", [])
	set_state("sound_history", [])
	set_state("effect_durations", {})
	set_state("volume_change_history", [])
	set_state("pitch_variations", {})
	set_state("effect_categories", {})
	set_state("cleanup_record", [])
	set_state("sound_performance", [])
	_initialize_sounds()

func _initialize_sounds() -> void:
	sound_effects = {
		"attack": SoundEffect.new("attack", "Attack Sound", 0.8),
		"hit": SoundEffect.new("hit", "Hit Sound", 0.7),
		"spell_cast": SoundEffect.new("spell_cast", "Spell Cast", 0.9),
		"footstep": SoundEffect.new("footstep", "Footstep", 0.5),
		"pickup": SoundEffect.new("pickup", "Pickup Item", 0.6),
		"levelup": SoundEffect.new("levelup", "Level Up", 1.0),
		"damage": SoundEffect.new("damage", "Damage", 0.8),
		"heal": SoundEffect.new("heal", "Heal", 0.7),
		"coin_drop": SoundEffect.new("coin_drop", "Coin Drop", 0.4),
		"door_open": SoundEffect.new("door_open", "Door Open", 0.6)
	}

func play_sound(sound_id: String) -> bool:
	if sound_id in sound_effects:
		var active = get_state("active_sounds", [])
		active.append(sound_id)
		set_state("active_sounds", active)
		_record_sound_history(sound_id)
		sound_played.emit(sound_id)
		emit_event("sound_played", sound_id)
		return true
	return false

func stop_sound(sound_id: String) -> bool:
	var active = get_state("active_sounds", [])
	if sound_id in active:
		active.erase(sound_id)
		set_state("active_sounds", active)
		sound_stopped.emit(sound_id)
		emit_event("sound_stopped", sound_id)
		return true
	return false

func get_sound(sound_id: String) -> SoundEffect:
	return sound_effects.get(sound_id, null)

func set_master_volume(volume: float) -> void:
	set_state("master_volume", clampf(volume, 0.0, 1.0))
	emit_event("master_volume_changed", volume)

func set_sfx_volume(volume: float) -> void:
	set_state("sfx_volume", clampf(volume, 0.0, 1.0))
	emit_event("sfx_volume_changed", volume)

func get_effective_volume(sound_id: String) -> float:
	var sound = get_sound(sound_id)
	if sound:
		var master = get_state("master_volume", 1.0)
		var sfx = get_state("sfx_volume", 0.8)
		return sound.volume * master * sfx
	return 0.0

func get_sound_text() -> String:
	var text = "Sound Effects\n"
	text += "Master: %.0f%% | SFX: %.0f%%\n" % [get_state("master_volume", 1.0) * 100.0, get_state("sfx_volume", 0.8) * 100.0]
	text += "Active: %d sounds" % get_state("active_sounds", []).size()
	return text

func _record_sound_history(sound_id: String) -> void:
	var history = get_state("sound_history", [])
	history.append({"sound": sound_id, "time": Time.get_ticks_msec(), "volume": get_effective_volume(sound_id)})
	if history.size() > 50:
		history.pop_front()
	set_state("sound_history", history)

func set_effect_duration(sound_id: String, duration_ms: int) -> void:
	var durations = get_state("effect_durations", {})
	durations[sound_id] = duration_ms
	set_state("effect_durations", durations)

func get_effect_duration(sound_id: String) -> int:
	var durations = get_state("effect_durations", {})
	return durations.get(sound_id, 0)

func record_volume_change(old_volume: float, new_volume: float, change_type: String) -> void:
	var history = get_state("volume_change_history", [])
	history.append({"old": old_volume, "new": new_volume, "type": change_type, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("volume_change_history", history)

func set_pitch_variation(sound_id: String, variation: float) -> void:
	var variations = get_state("pitch_variations", {})
	variations[sound_id] = clampf(variation, 0.5, 2.0)
	set_state("pitch_variations", variations)

func get_pitch_variation(sound_id: String) -> float:
	var variations = get_state("pitch_variations", {})
	return variations.get(sound_id, 1.0)

func set_effect_category(sound_id: String, category: String) -> void:
	var categories = get_state("effect_categories", {})
	categories[sound_id] = category
	set_state("effect_categories", categories)
	emit_event("category_assigned", sound_id)

func get_effects_by_category(category: String) -> Array:
	var categories = get_state("effect_categories", {})
	var result = []
	for sound_id in categories:
		if categories[sound_id] == category:
			result.append(sound_id)
	return result

func record_cleanup(sound_id: String, reason: String) -> void:
	var cleanup = get_state("cleanup_record", [])
	cleanup.append({"sound": sound_id, "reason": reason, "time": Time.get_ticks_msec()})
	if cleanup.size() > 30:
		cleanup.pop_front()
	set_state("cleanup_record", cleanup)

func record_sound_performance(sound_id: String, play_duration_ms: int, success: bool) -> void:
	var perf = get_state("sound_performance", [])
	perf.append({"sound": sound_id, "duration": play_duration_ms, "success": success, "time": Time.get_ticks_msec()})
	if perf.size() > 50:
		perf.pop_front()
	set_state("sound_performance", perf)

func get_sound_history() -> Array:
	return get_state("sound_history", [])
