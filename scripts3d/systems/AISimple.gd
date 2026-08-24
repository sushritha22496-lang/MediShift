extends BaseSystemSimple

class_name AISimple

class AIBehavior:
	var id: String
	var name: String
	var behavior_type: String
	var priority: int
	var enabled: bool
	func _init(p_id: String, p_name: String, p_type: String, p_priority: int = 0) -> void:
		id = p_id
		name = p_name
		behavior_type = p_type
		priority = p_priority
		enabled = true

var behaviors: Dictionary = {}

signal behavior_activated(behavior_id: String)
signal behavior_deactivated(behavior_id: String)
signal decision_made(behavior_id: String, decision: String)

func _ready() -> void:
	set_state("active_behavior", "")
	_initialize_behaviors()

func _initialize_behaviors() -> void:
	behaviors = {
		"wander": AIBehavior.new("wander", "Wander", "movement", 1),
		"patrol": AIBehavior.new("patrol", "Patrol", "movement", 2),
		"chase": AIBehavior.new("chase", "Chase Target", "combat", 3),
		"flee": AIBehavior.new("flee", "Flee", "survival", 3),
		"attack": AIBehavior.new("attack", "Attack", "combat", 4),
		"defend": AIBehavior.new("defend", "Defend", "defensive", 3),
		"rest": AIBehavior.new("rest", "Rest", "utility", 1),
		"socialise": AIBehavior.new("socialise", "Socialise", "social", 1)
	}

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
	text += "Behaviors: %d" % behaviors.size()
	return text
