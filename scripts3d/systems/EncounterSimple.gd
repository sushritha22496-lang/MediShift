extends Node

class_name EncounterSimple

class Encounter:
	var id: String
	var title: String
	var description: String
	var location: String
	var difficulty: String
	var reward_gold: float
	var encountered: bool = false

	func _init(p_id: String, p_title: String, p_desc: String, p_loc: String, p_diff: String) -> void:
		id = p_id
		title = p_title
		description = p_desc
		location = p_loc
		difficulty = p_diff

var encounters: Array[Encounter] = []
var active_encounter: Encounter = null

signal encounter_started(encounter: Encounter)
signal encounter_completed(encounter: Encounter)
signal encounter_chain_triggered(chain_id: String)
signal rare_variant_encountered(variant_id: String)

func _ready() -> void:
	if not is_node_ready():
		await tree_entered
	set_state("encounter_variants", {})
	set_state("encounter_rewards", {})
	set_state("encounter_chains", {})
	set_state("rare_encounters", [])
	set_state("completion_history", [])
	_initialize_encounters()

func _initialize_encounters() -> void:
	var enc1 = Encounter.new("bandit_ambush", "Bandit Ambush", "You're surrounded by bandits", "Forest", "Hard")
	enc1.reward_gold = 200

	var enc2 = Encounter.new("wild_beast", "Wild Beast", "A fierce beast attacks", "Mountains", "Very Hard")
	enc2.reward_gold = 300

	var enc3 = Encounter.new("merchant_meeting", "Merchant Meeting", "Meet a traveling merchant", "Road", "Easy")
	enc3.reward_gold = 50

	var enc4 = Encounter.new("lost_child", "Lost Child", "Find and help a lost child", "Village", "Easy")
	enc4.reward_gold = 100

	var enc5 = Encounter.new("sacred_ritual", "Sacred Ritual", "Witness an ancient ritual", "Temple", "Medium")
	enc5.reward_gold = 150

	encounters = [enc1, enc2, enc3, enc4, enc5]

func start_random_encounter() -> Encounter:
	var available = encounters.filter(func(e): return not e.encountered)
	if available.is_empty():
		return null

	var encounter = available[randi() % available.size()]
	encounter.encountered = true
	active_encounter = encounter
	encounter_started.emit(encounter)
	print("⚔️ Encounter: %s" % encounter.title)
	return encounter

func start_encounter(encounter_id: String) -> bool:
	for encounter in encounters:
		if encounter.id == encounter_id:
			encounter.encountered = true
			active_encounter = encounter
			encounter_started.emit(encounter)
			return true
	return false

func complete_encounter() -> void:
	if active_encounter:
		if has_state("completion_history"):
			var history = get_state("completion_history", [])
			history.append({"id": active_encounter.id, "difficulty": active_encounter.difficulty, "reward": active_encounter.reward_gold, "time": Time.get_ticks_msec()})
			if history.size() > 50:
				history.pop_front()
			set_state("completion_history", history)
		encounter_completed.emit(active_encounter)
		active_encounter = null

func get_encounter(encounter_id: String) -> Encounter:
	for encounter in encounters:
		if encounter.id == encounter_id:
			return encounter
	return null

func get_encounters_text() -> String:
	var text = "Encounters:\n"
	for encounter in encounters:
		var status = "✓" if encounter.encountered else "?"
		text += "%s %s (%s)\n" % [status, encounter.title, encounter.difficulty]
	return text

func get_total_encounters() -> int:
	return encounters.size()

func get_completed_encounters() -> int:
	return encounters.filter(func(e): return e.encountered).size()

func add_encounter_variant(encounter_id: String, variant_id: String, properties: Dictionary) -> void:
	if not has_state("encounter_variants"):
		return
	var variants = get_state("encounter_variants", {})
	if encounter_id not in variants:
		variants[encounter_id] = []
	variants[encounter_id].append({"id": variant_id, "properties": properties})
	set_state("encounter_variants", variants)

func trigger_encounter_chain(chain_id: String) -> void:
	var chains = get_state("encounter_chains", {})
	chains[chain_id] = true
	set_state("encounter_chains", chains)
	encounter_chain_triggered.emit(chain_id)

func get_rare_variant() -> String:
	if randf() < 0.1:
		var variant_id = "rare_variant_%d" % randi()
		var rare = get_state("rare_encounters", [])
		rare.append(variant_id)
		set_state("rare_encounters", rare)
		rare_variant_encountered.emit(variant_id)
		return variant_id
	return ""

func track_encounter_rewards(encounter_id: String, rewards: Dictionary) -> void:
	var reward_tracking = get_state("encounter_rewards", {})
	reward_tracking[encounter_id] = rewards
	set_state("encounter_rewards", reward_tracking)

func get_encounter_rewards(encounter_id: String) -> Dictionary:
	var reward_tracking = get_state("encounter_rewards", {})
	return reward_tracking.get(encounter_id, {})

func get_encounter_statistics() -> Dictionary:
	return {
		"total_encounters": get_total_encounters(),
		"completed_encounters": get_completed_encounters(),
		"completion_percent": (float(get_completed_encounters()) / float(get_total_encounters()) * 100.0) if get_total_encounters() > 0 else 0.0,
		"completions_recorded": get_state("completion_history", []).size(),
		"rare_encounters_found": get_state("rare_encounters", []).size(),
		"chains_triggered": get_state("encounter_chains", {}).size(),
		"variants_registered": get_state("encounter_variants", {}).size(),
		"has_active_encounter": active_encounter != null
	}
