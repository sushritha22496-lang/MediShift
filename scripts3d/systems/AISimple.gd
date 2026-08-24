extends BaseSystemSimple

class_name AISimple

class AIBehavior:
	var id: String
	var name: String
	var behavior_type: String
	var priority: int
	var enabled: bool
	var energy_cost: float
	var conditions: Dictionary
	var weight: float
	func _init(p_id: String, p_name: String, p_type: String, p_priority: int = 0, p_cost: float = 10.0) -> void:
		id = p_id
		name = p_name
		behavior_type = p_type
		priority = p_priority
		enabled = true
		energy_cost = p_cost
		conditions = {}
		weight = 1.0

var behaviors: Dictionary = {}

signal behavior_activated(behavior_id: String)
signal behavior_deactivated(behavior_id: String)
signal decision_made(behavior_id: String, decision: String)
signal behavior_tree_changed(path: String)
signal ai_state_updated(state: String)

func _ready() -> void:
	set_state("active_behavior", "")
	set_state("energy", 100.0)
	set_state("emotional_state", "neutral")
	set_state("threat_level", 0.0)
	set_state("memory", {})
	set_state("decision_history", [])
	set_state("behavior_log", [])
	set_state("threat_sources", {})
	set_state("memory_events", [])
	_initialize_behaviors()

func _initialize_behaviors() -> void:
	behaviors = {
		"wander": AIBehavior.new("wander", "Wander", "movement", 1, 5.0),
		"patrol": AIBehavior.new("patrol", "Patrol", "movement", 2, 15.0),
		"chase": AIBehavior.new("chase", "Chase Target", "combat", 3, 30.0),
		"flee": AIBehavior.new("flee", "Flee", "survival", 5, 40.0),
		"attack": AIBehavior.new("attack", "Attack", "combat", 4, 25.0),
		"defend": AIBehavior.new("defend", "Defend", "defensive", 3, 20.0),
		"rest": AIBehavior.new("rest", "Rest", "utility", 0, -20.0),
		"socialise": AIBehavior.new("socialise", "Socialise", "social", 1, 10.0)
	}
	for b in behaviors.values():
		b.weight = 1.0 + randf_range(-0.2, 0.2)

func activate_behavior(behavior_id: String) -> bool:
	if behavior_id in behaviors:
		set_state("active_behavior", behavior_id)
		behavior_activated.emit(behavior_id)
		emit_event("behavior_activated", behavior_id)
		return true
	return false

func deactivate_behavior(behavior_id: String) -> void:
	if get_state("active_behavior", "") == behavior_id:
		set_state("active_behavior", "")
		behavior_deactivated.emit(behavior_id)
		emit_event("behavior_deactivated", behavior_id)

func get_behavior(behavior_id: String) -> AIBehavior:
	return behaviors.get(behavior_id, null)

func get_high_priority_behavior() -> AIBehavior:
	var highest: AIBehavior = null
	var max_priority = -1
	for behavior in behaviors.values():
		if behavior.enabled and behavior.priority > max_priority:
			max_priority = behavior.priority
			highest = behavior
	return highest

func make_decision(behavior_id: String, options: Array[String]) -> String:
	if options.is_empty():
		return ""
	var decision = options[randi() % options.size()]
	decision_made.emit(behavior_id, decision)
	emit_event("decision_made", behavior_id)
	return decision

func enable_behavior(behavior_id: String) -> void:
	if behavior_id in behaviors:
		behaviors[behavior_id].enabled = true
		emit_event("behavior_enabled", behavior_id)

func disable_behavior(behavior_id: String) -> void:
	if behavior_id in behaviors:
		behaviors[behavior_id].enabled = false
		deactivate_behavior(behavior_id)
		emit_event("behavior_disabled", behavior_id)

func get_active_behavior() -> AIBehavior:
	var behavior_id = get_state("active_behavior", "")
	return get_behavior(behavior_id) if behavior_id != "" else null

func get_ai_text() -> String:
	var active = get_active_behavior()
	var text = "AI System\n"
	if active:
		text += "Active: %s (Priority: %d)\n" % [active.name, active.priority]
	else:
		text += "Active: None\n"
	var energy = get_state("energy", 100.0)
	text += "Energy: %.0f | Mood: %s\n" % [energy, get_state("emotional_state", "neutral")]
	text += "Threat: %.0f" % get_state("threat_level", 0.0)
	return text

func evaluate_behavior(behavior_id: String) -> float:
	if behavior_id not in behaviors:
		return 0.0
	var behavior = behaviors[behavior_id]
	if not behavior.enabled:
		return 0.0
	var score = float(behavior.priority) * behavior.weight
	var energy = get_state("energy", 100.0)
	if energy < behavior.energy_cost:
		score *= 0.5
	var threat = get_state("threat_level", 0.0)
	if behavior.behavior_type == "survival" and threat > 50.0:
		score *= 2.0
	return score

func select_best_behavior() -> AIBehavior:
	var best_id = ""
	var best_score = -1.0
	for behavior_id in behaviors.keys():
		var score = evaluate_behavior(behavior_id)
		if score > best_score:
			best_score = score
			best_id = behavior_id
	return get_behavior(best_id) if best_id != "" else null

func update_emotional_state(trigger: String, intensity: float) -> void:
	var state = "neutral"
	if intensity > 75.0:
		state = "aggressive" if trigger == "threat" else "excited"
	elif intensity > 50.0:
		state = "alert" if trigger == "threat" else "cautious"
	elif intensity < 25.0:
		state = "calm"
	set_state("emotional_state", state)
	emit_event("emotion_changed", state)

func update_threat_level(threat: float) -> void:
	var current = get_state("threat_level", 0.0)
	var new_threat = lerpf(current, threat, 0.1)
	set_state("threat_level", new_threat)
	update_emotional_state("threat", new_threat)

func spend_energy(amount: float) -> void:
	var energy = get_state("energy", 100.0)
	energy = maxf(0.0, energy - amount)
	set_state("energy", energy)
	if energy < 30.0:
		activate_behavior("rest")

func restore_energy(amount: float) -> void:
	var energy = get_state("energy", 100.0)
	energy = minf(100.0, energy + amount)
	set_state("energy", energy)

func record_memory(event_type: String, details: Dictionary) -> void:
	var events = get_state("memory_events", [])
	events.append({"type": event_type, "details": details, "timestamp": Time.get_ticks_msec()})
	if events.size() > 50:
		events.pop_front()
	set_state("memory_events", events)
	emit_event("memory_recorded", event_type)

func record_decision(behavior_id: String, decision: String, outcome: float) -> void:
	var history = get_state("decision_history", [])
	history.append({"behavior": behavior_id, "decision": decision, "outcome": outcome, "time": Time.get_ticks_msec()})
	if history.size() > 100:
		history.pop_front()
	set_state("decision_history", history)

func add_threat_source(source: String, intensity: float) -> void:
	var threats = get_state("threat_sources", {})
	threats[source] = intensity
	set_state("threat_sources", threats)
	update_threat_level(get_total_threat())

func get_total_threat() -> float:
	var threats = get_state("threat_sources", {})
	var total = 0.0
	for threat_value in threats.values():
		total += threat_value
	return total

func log_behavior_execution(behavior_id: String, duration: float, success: bool) -> void:
	var log = get_state("behavior_log", [])
	log.append({"behavior": behavior_id, "duration": duration, "success": success, "time": Time.get_ticks_msec()})
	if log.size() > 100:
		log.pop_front()
	set_state("behavior_log", log)

func get_behavior_success_rate(behavior_id: String) -> float:
	var log = get_state("behavior_log", [])
	var successes = 0.0
	var total = 0.0
	for entry in log:
		if entry["behavior"] == behavior_id:
			total += 1.0
			if entry["success"]:
				successes += 1.0
	return (successes / total * 100.0) if total > 0 else 0.0

func get_memory_events() -> Array:
	return get_state("memory_events", [])
