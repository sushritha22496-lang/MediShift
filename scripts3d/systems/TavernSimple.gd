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
	set_state("rumor_tracking", {})
	set_state("rumor_verification", {})
	set_state("tavern_reputation", 0.0)
	set_state("tavern_quests", [])
	set_state("bard_effects", [])
	set_state("npc_contributions", {})
	set_state("tavern_food_log", [])
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

func track_rumor_investigation(rumor_id: String, investigation_type: String) -> void:
	var tracking = get_state("rumor_tracking", {})
	if rumor_id not in tracking:
		tracking[rumor_id] = []
	tracking[rumor_id].append(investigation_type)
	set_state("rumor_tracking", tracking)
	emit_event("rumor_tracked", rumor_id)

func verify_rumor(rumor_id: String, verified: bool) -> void:
	var verification = get_state("rumor_verification", {})
	verification[rumor_id] = {"verified": verified, "time": Time.get_ticks_msec()}
	set_state("rumor_verification", verification)
	if verified:
		var reputation = get_state("tavern_reputation", 0.0)
		set_state("tavern_reputation", reputation + 0.1)
	emit_event("rumor_verified", rumor_id)

func add_tavern_quest(quest_data: Dictionary) -> void:
	var quests = get_state("tavern_quests", [])
	quests.append({"data": quest_data, "time": Time.get_ticks_msec()})
	if quests.size() > 20:
		quests.pop_front()
	set_state("tavern_quests", quests)
	emit_event("tavern_quest_added", quest_data)

func apply_bard_effect(effect: String, duration_ms: int) -> void:
	var effects = get_state("bard_effects", [])
	effects.append({"effect": effect, "start": Time.get_ticks_msec(), "duration": duration_ms})
	set_state("bard_effects", effects)
	emit_event("bard_effect_applied", effect)

func record_npc_contribution(npc_id: String, contribution: String) -> void:
	var contributions = get_state("npc_contributions", {})
	if npc_id not in contributions:
		contributions[npc_id] = []
	contributions[npc_id].append(contribution)
	set_state("npc_contributions", contributions)

func order_tavern_food(food_type: String, cost: float) -> void:
	var log = get_state("tavern_food_log", [])
	log.append({"food": food_type, "cost": cost, "time": Time.get_ticks_msec()})
	if log.size() > 50:
		log.pop_front()
	var spent = get_state("gold_spent", 0.0)
	set_state("gold_spent", spent + cost)
	set_state("tavern_food_log", log)
	emit_event("food_ordered", food_type)

func get_tavern_reputation() -> float:
	return get_state("tavern_reputation", 0.0)

func set_tavern_reputation(reputation: float) -> void:
	set_state("tavern_reputation", clampf(reputation, 0.0, 1.0))

func get_active_bard_effects() -> Array:
	var effects = get_state("bard_effects", [])
	var current_time = Time.get_ticks_msec()
	return effects.filter(func(e): return (current_time - e["start"]) < e["duration"])

func get_verified_rumors() -> Array[Rumor]:
	var verification = get_state("rumor_verification", {})
	var verified: Array[Rumor] = []
	for rumor in rumors:
		if rumor.id in verification and verification[rumor.id]["verified"]:
			verified.append(rumor)
	return verified
