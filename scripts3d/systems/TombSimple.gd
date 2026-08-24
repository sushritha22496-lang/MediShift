extends BaseSystemSimple

class_name TombSimple

class Tomb:
	var id: String
	var name: String
	var location: String
	var description: String
	var guardian: String
	var treasures: int
	var discovered: bool
	var opened: bool
	var difficulty: int
	func _init(p_id: String, p_name: String, p_loc: String, p_desc: String, p_guard: String, p_diff: int) -> void:
		id = p_id
		name = p_name
		location = p_loc
		description = p_desc
		guardian = p_guard
		treasures = randi_range(3, 8)
		discovered = false
		opened = false
		difficulty = p_diff

var tombs: Array[Tomb] = []

signal tomb_discovered(tomb: Tomb)
signal tomb_opened(tomb_id: String)
signal guardian_defeated(tomb_id: String)
signal treasures_found(tomb_id: String, treasure_count: int)

func _ready() -> void:
	set_state("discovered_tombs", [])
	set_state("opened_tombs", [])
	set_state("guardian_defeats", {})
	set_state("tomb_seals", {})
	set_state("tomb_artifacts", {})
	set_state("tomb_curses", [])
	set_state("guardian_respawn_timers", {})
	set_state("tomb_exploration_progress", {})
	set_state("ancient_knowledge", [])
	set_state("guardian_stats", {})
	_initialize_tombs()

func _initialize_tombs() -> void:
	tombs = [
		Tomb.new("t1", "Tomb of the First King", "Ancient Ruins", "Resting place of Raghu dynasty", "Stone Golem", 2),
		Tomb.new("t2", "Sage's Mausoleum", "Temple Grounds", "A wise sage's eternal resting place", "Spirit Guardian", 2),
		Tomb.new("t3", "Warrior's Crypt", "Mountain Peak", "Burial of legendary warriors", "Cursed Knight", 3),
		Tomb.new("t4", "Divine Sanctuary", "Sacred Shrine", "Holy ground of ancient gods", "Divine Protector", 4),
		Tomb.new("t5", "Demon's Prison", "Dark Cavern", "Sealing point of ancient evil", "Demon Warden", 5)
	]

func discover_tomb(tomb_id: String) -> bool:
	var tomb = _get_tomb(tomb_id)
	if tomb and not tomb.discovered:
		tomb.discovered = true
		var discovered = get_state("discovered_tombs", [])
		discovered.append(tomb_id)
		set_state("discovered_tombs", discovered)
		tomb_discovered.emit(tomb)
		emit_event("tomb_discovered", tomb_id)
		return true
	return false

func open_tomb(tomb_id: String) -> bool:
	var tomb = _get_tomb(tomb_id)
	if tomb and tomb.discovered and not tomb.opened:
		tomb.opened = true
		var opened = get_state("opened_tombs", [])
		opened.append(tomb_id)
		set_state("opened_tombs", opened)
		tomb_opened.emit(tomb_id)
		emit_event("tomb_opened", tomb_id)
		treasures_found.emit(tomb_id, tomb.treasures)
		return true
	return false

func defeat_guardian(tomb_id: String) -> void:
	var tomb = _get_tomb(tomb_id)
	if tomb:
		guardian_defeated.emit(tomb_id)
		emit_event("guardian_defeated", tomb_id)

func get_tomb(tomb_id: String) -> Tomb:
	return _get_tomb(tomb_id)

func get_discovered_tombs() -> Array[Tomb]:
	var discovered_ids = get_state("discovered_tombs", [])
	var discovered: Array[Tomb] = []
	for t in tombs:
		if t.id in discovered_ids:
			discovered.append(t)
	return discovered

func get_opened_tombs() -> Array[Tomb]:
	var opened_ids = get_state("opened_tombs", [])
	var opened: Array[Tomb] = []
	for t in tombs:
		if t.id in opened_ids:
			opened.append(t)
	return opened

func get_tomb_text() -> String:
	var discovered = get_discovered_tombs()
	var opened = get_opened_tombs()
	var text = "Tombs: %d discovered | %d opened\n" % [discovered.size(), opened.size()]
	for tomb in discovered.slice(0, 3):
		var status = "🔓" if tomb.opened else "🔒"
		text += "%s [★%d] %s (%d treasures)\n" % [status, tomb.difficulty, tomb.name, tomb.treasures]
	return text

func _get_tomb(tomb_id: String) -> Tomb:
	for tomb in tombs:
		if tomb.id == tomb_id:
			return tomb
	return null

func record_guardian_defeat(tomb_id: String, defeat_data: Dictionary) -> void:
	var defeats = get_state("guardian_defeats", {})
	if tomb_id not in defeats:
		defeats[tomb_id] = []
	defeats[tomb_id].append({"data": defeat_data, "time": Time.get_ticks_msec()})
	if defeats[tomb_id].size() > 10:
		defeats[tomb_id].pop_front()
	set_state("guardian_defeats", defeats)
	emit_event("guardian_defeat_recorded", tomb_id)

func set_tomb_seal_status(tomb_id: String, sealed: bool) -> void:
	var seals = get_state("tomb_seals", {})
	seals[tomb_id] = {"sealed": sealed, "time": Time.get_ticks_msec()}
	set_state("tomb_seals", seals)
	emit_event("seal_status_changed", tomb_id)

func is_tomb_sealed(tomb_id: String) -> bool:
	var seals = get_state("tomb_seals", {})
	if tomb_id not in seals:
		return true
	return seals[tomb_id]["sealed"]

func record_tomb_artifact(tomb_id: String, artifact: Dictionary) -> void:
	var artifacts = get_state("tomb_artifacts", {})
	if tomb_id not in artifacts:
		artifacts[tomb_id] = []
	artifacts[tomb_id].append(artifact)
	set_state("tomb_artifacts", artifacts)
	emit_event("artifact_found", tomb_id)

func apply_tomb_curse(tomb_id: String, curse: String) -> void:
	var curses = get_state("tomb_curses", [])
	curses.append({"tomb": tomb_id, "curse": curse, "time": Time.get_ticks_msec()})
	if curses.size() > 30:
		curses.pop_front()
	set_state("tomb_curses", curses)
	emit_event("curse_applied", tomb_id)

func set_guardian_respawn_timer(tomb_id: String, respawn_time_ms: int) -> void:
	var timers = get_state("guardian_respawn_timers", {})
	timers[tomb_id] = {"start": Time.get_ticks_msec(), "duration": respawn_time_ms}
	set_state("guardian_respawn_timers", timers)

func has_guardian_respawned(tomb_id: String) -> bool:
	var timers = get_state("guardian_respawn_timers", {})
	if tomb_id not in timers:
		return false
	var current = Time.get_ticks_msec()
	var start = timers[tomb_id]["start"]
	var duration = timers[tomb_id]["duration"]
	return (current - start) > duration

func update_tomb_exploration_progress(tomb_id: String, progress: float) -> void:
	var prog = get_state("tomb_exploration_progress", {})
	prog[tomb_id] = clampf(progress, 0.0, 1.0)
	set_state("tomb_exploration_progress", prog)
	emit_event("exploration_progress_updated", tomb_id)

func record_ancient_knowledge(knowledge: String) -> void:
	var knowledge_list = get_state("ancient_knowledge", [])
	knowledge_list.append({"knowledge": knowledge, "time": Time.get_ticks_msec()})
	if knowledge_list.size() > 50:
		knowledge_list.pop_front()
	set_state("ancient_knowledge", knowledge_list)
	emit_event("knowledge_gained", knowledge)

func set_guardian_stats(tomb_id: String, stats: Dictionary) -> void:
	var guardian_stats = get_state("guardian_stats", {})
	guardian_stats[tomb_id] = stats
	set_state("guardian_stats", guardian_stats)

func get_guardian_stats(tomb_id: String) -> Dictionary:
	var guardian_stats = get_state("guardian_stats", {})
	return guardian_stats.get(tomb_id, {})

func get_tomb_artifacts(tomb_id: String) -> Array:
	var artifacts = get_state("tomb_artifacts", {})
	return artifacts.get(tomb_id, [])

func get_tomb_exploration_progress(tomb_id: String) -> float:
	var prog = get_state("tomb_exploration_progress", {})
	return prog.get(tomb_id, 0.0)
