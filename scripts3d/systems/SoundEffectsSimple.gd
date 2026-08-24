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
