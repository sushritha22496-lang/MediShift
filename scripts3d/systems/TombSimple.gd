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
