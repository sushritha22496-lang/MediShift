extends BaseSystemSimple

class_name TavernSimple

class Rumor:
	var id: String
	var text: String
	var source: String
	var reliability: float
	func _init(p_id: String, p_text: String, p_source: String, p_reliability: float) -> void:
		id = p_id
		text = p_text
		source = p_source
		reliability = p_reliability

var rumors: Array[Rumor] = []

signal rumor_heard(rumor: Rumor)
signal tavern_visited
signal ale_served

func _ready() -> void:
	set_state("visited_count", 0)
	set_state("gold_spent", 0.0)
	_initialize_rumors()

func _initialize_rumors() -> void:
	rumors = [
		Rumor.new("r1", "They say a dragon sleeps in the mountains.", "drunk_merchant", 0.4),
		Rumor.new("r2", "Sita is held in a tower to the east!", "mysterious_stranger", 0.7),
		Rumor.new("r3", "The forest spirits guard ancient treasures.", "old_sage", 0.8),
		Rumor.new("r4", "There's a bounty on the bandits north of town.", "bounty_board", 0.9),
		Rumor.new("r5", "Lost ruins are hidden beneath the temple.", "scholar", 0.6)
	]

func visit_tavern() -> void:
	var count = get_state("visited_count", 0)
	count += 1
	set_state("visited_count", count)
	tavern_visited.emit()
	emit_event("tavern_visited", count)

func serve_ale(cost: float) -> bool:
	ale_served.emit()
	var spent = get_state("gold_spent", 0.0)
	spent += cost
	set_state("gold_spent", spent)
	emit_event("ale_served", cost)
	return true

func hear_rumor() -> Rumor:
	if rumors.is_empty():
		return null
	var rumor = rumors[randi() % rumors.size()]
	rumor_heard.emit(rumor)
	emit_event("rumor_heard", rumor.id)
	return rumor

func get_reliable_rumors() -> Array[Rumor]:
	return rumors.filter(func(r): return r.reliability >= 0.7)

func get_all_rumors() -> Array[Rumor]:
	return rumors

func get_rumor_by_id(rumor_id: String) -> Rumor:
	for rumor in rumors:
		if rumor.id == rumor_id:
			return rumor
	return null

func add_rumor(text: String, source: String, reliability: float) -> void:
	var id = "r%d" % randi()
	var rumor = Rumor.new(id, text, source, reliability)
	rumors.append(rumor)
	emit_event("rumor_added", id)

func get_tavern_text() -> String:
	var text = "Tavern\nVisits: %d | Spent: %.0f gold\n" % [get_state("visited_count", 0), get_state("gold_spent", 0.0)]
	text += "Latest rumors:\n"
	for i in range(mini(3, rumors.size())):
		text += "- %s (%.0f%%)\n" % [rumors[i].text.substr(0, 40), rumors[i].reliability * 100.0]
	return text
