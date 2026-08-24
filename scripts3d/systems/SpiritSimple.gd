extends BaseSystemSimple

class_name SpiritSimple

class Spirit:
	var id: String
	var name: String
	var spirit_type: String
	var power: int
	var blessing: String
	var encountered: bool
	func _init(p_id: String, p_name: String, p_type: String, p_power: int, p_blessing: String) -> void:
		id = p_id
		name = p_name
		spirit_type = p_type
		power = p_power
		blessing = p_blessing
		encountered = false

var spirits: Array[Spirit] = []

signal spirit_encountered(spirit: Spirit)
signal blessing_granted(spirit_id: String, blessing: String)
signal spirit_appeased

func _ready() -> void:
	set_state("encountered_spirits", [])
	set_state("active_blessings", [])
	set_state("spirit_affinity", {})
	set_state("blessing_effectiveness", {})
	set_state("appeasement_requirements", {})
	set_state("blessing_durations", {})
	set_state("spirit_manifestations", [])
	set_state("spirit_pacts", {})
	set_state("blessing_conflicts", [])
	set_state("spirit_resonance", {})
	_initialize_spirits()

func _initialize_spirits() -> void:
	spirits = [
		Spirit.new("s1", "Forest Guardian", "nature", 3, "forest_guide"),
		Spirit.new("s2", "River Sprite", "water", 2, "water_crossing"),
		Spirit.new("s3", "Mountain Warden", "earth", 4, "stone_skin"),
		Spirit.new("s4", "Sky Herald", "air", 3, "swift_wind"),
		Spirit.new("s5", "Ancient Soul", "ancestral", 5, "wisdom_echo")
	]

func encounter_spirit(spirit_id: String) -> bool:
	var spirit = _get_spirit(spirit_id)
	if spirit and not spirit.encountered:
		spirit.encountered = true
		var encountered = get_state("encountered_spirits", [])
		encountered.append(spirit_id)
		set_state("encountered_spirits", encountered)
		spirit_encountered.emit(spirit)
		emit_event("spirit_encountered", spirit_id)
		return true
	return false

func grant_blessing(spirit_id: String) -> String:
	var spirit = _get_spirit(spirit_id)
	if spirit and spirit.encountered:
		var blessings = get_state("active_blessings", [])
		if spirit.blessing not in blessings:
			blessings.append(spirit.blessing)
			set_state("active_blessings", blessings)
		blessing_granted.emit(spirit_id, spirit.blessing)
		emit_event("blessing_granted", spirit_id)
		return spirit.blessing
	return ""

func appease_spirit(spirit_id: String) -> void:
	var spirit = _get_spirit(spirit_id)
	if spirit:
		spirit_appeased.emit()
		emit_event("spirit_appeased", spirit_id)

func get_spirit(spirit_id: String) -> Spirit:
	return _get_spirit(spirit_id)

func get_encountered_spirits() -> Array[Spirit]:
	var encountered_ids = get_state("encountered_spirits", [])
	var encountered: Array[Spirit] = []
	for s in spirits:
		if s.id in encountered_ids:
			encountered.append(s)
	return encountered

func get_active_blessings() -> Array:
	return get_state("active_blessings", [])

func has_blessing(blessing: String) -> bool:
	return blessing in get_active_blessings()

func get_spirit_text() -> String:
	var encountered = get_encountered_spirits()
	var blessings = get_active_blessings()
	var text = "Spirits: %d encountered | %d blessings\n" % [encountered.size(), blessings.size()]
	for spirit in encountered:
		var blessed = " ✓" if spirit.blessing in blessings else ""
		text += "○ %s%s\n" % [spirit.name, blessed]
	return text

func _get_spirit(spirit_id: String) -> Spirit:
	for spirit in spirits:
		if spirit.id == spirit_id:
			return spirit
	return null

func track_spirit_affinity(spirit_type: String) -> void:
	var affinity = get_state("spirit_affinity", {})
	affinity[spirit_type] = affinity.get(spirit_type, 0) + 1
	set_state("spirit_affinity", affinity)
	emit_event("affinity_increased", spirit_type)

func set_blessing_effectiveness(blessing: String, effectiveness: float) -> void:
	var effects = get_state("blessing_effectiveness", {})
	effects[blessing] = clampf(effectiveness, 0.0, 1.0)
	set_state("blessing_effectiveness", effects)
	emit_event("effectiveness_set", blessing)

func add_appeasement_requirement(spirit_id: String, requirement: String) -> void:
	var reqs = get_state("appeasement_requirements", {})
	if spirit_id not in reqs:
		reqs[spirit_id] = []
	reqs[spirit_id].append(requirement)
	set_state("appeasement_requirements", reqs)
	emit_event("requirement_added", spirit_id)

func set_blessing_duration(blessing: String, duration_ms: int) -> void:
	var durations = get_state("blessing_durations", {})
	durations[blessing] = {"start": Time.get_ticks_msec(), "duration": duration_ms}
	set_state("blessing_durations", durations)

func record_spirit_manifestation(spirit_id: String, manifestation_type: String) -> void:
	var manifestations = get_state("spirit_manifestations", [])
	manifestations.append({"spirit": spirit_id, "type": manifestation_type, "time": Time.get_ticks_msec()})
	if manifestations.size() > 50:
		manifestations.pop_front()
	set_state("spirit_manifestations", manifestations)
	emit_event("manifestation_recorded", spirit_id)

func create_spirit_pact(spirit_id: String, pact_terms: Dictionary) -> void:
	var pacts = get_state("spirit_pacts", {})
	pacts[spirit_id] = {"terms": pact_terms, "established": Time.get_ticks_msec()}
	set_state("spirit_pacts", pacts)
	emit_event("pact_created", spirit_id)

func record_blessing_conflict(blessing1: String, blessing2: String) -> void:
	var conflicts = get_state("blessing_conflicts", [])
	conflicts.append({"blessing1": blessing1, "blessing2": blessing2})
	if conflicts.size() > 30:
		conflicts.pop_front()
	set_state("blessing_conflicts", conflicts)

func update_spirit_resonance(spirit_type: String, resonance: float) -> void:
	var resonance_map = get_state("spirit_resonance", {})
	resonance_map[spirit_type] = clampf(resonance, 0.0, 1.0)
	set_state("spirit_resonance", resonance_map)
	emit_event("resonance_updated", spirit_type)

func get_blessing_effectiveness(blessing: String) -> float:
	var effects = get_state("blessing_effectiveness", {})
	return effects.get(blessing, 0.5)

func get_spirit_resonance(spirit_type: String) -> float:
	var resonance_map = get_state("spirit_resonance", {})
	return resonance_map.get(spirit_type, 0.0)

func is_blessing_expired(blessing: String) -> bool:
	var durations = get_state("blessing_durations", {})
	if blessing not in durations:
		return false
	var current_time = Time.get_ticks_msec()
	var start = durations[blessing]["start"]
	var duration = durations[blessing]["duration"]
	return (current_time - start) > duration

func get_affinity_stat() -> Dictionary:
	return get_state("spirit_affinity", {})
