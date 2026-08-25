extends BaseSystemSimple

class_name CreditsSimple

class CreditEntry:
	var role: String
	var name: String
	var contribution: String
	func _init(p_role: String, p_name: String, p_contribution: String = "") -> void:
		role = p_role
		name = p_name
		contribution = p_contribution

var credits: Array[CreditEntry] = []

signal credits_started
signal credits_ended
signal credit_section_reached(section: String)

func _ready() -> void:
	set_state("credits_viewed", false)
	set_state("credits_view_time", 0)
	set_state("section_timing", {})
	set_state("credits_skipped", false)
	set_state("contribution_points", {})
	set_state("credit_performance", [])
	set_state("special_tributes", [])
	set_state("credits_statistics", {})
	set_state("credits_update_history", [])
	_initialize_credits()

func _initialize_credits() -> void:
	credits = [
		CreditEntry.new("Game Design", "Development Team", "Core gameplay mechanics"),
		CreditEntry.new("Programming", "Claude AI", "Game systems and logic"),
		CreditEntry.new("Story", "Ramayana", "Epic narrative"),
		CreditEntry.new("Art Direction", "Game Engine", "Godot 4.x"),
		CreditEntry.new("Music", "Ambient Composer", "Background score"),
		CreditEntry.new("Sound Design", "Audio Team", "Effects and ambience"),
		CreditEntry.new("QA Testing", "Community", "Bug reports and feedback"),
		CreditEntry.new("Special Thanks", "Players", "For playing this game")
	]

func start_credits() -> void:
	record_update("started", "")
	credits_started.emit()
	emit_event("credits_started", "")

func end_credits() -> void:
	set_state("credits_viewed", true)
	record_update("ended", "")
	credits_ended.emit()
	emit_event("credits_ended", "")

func get_credits() -> Array[CreditEntry]:
	return credits

func get_credits_by_role(role: String) -> Array[CreditEntry]:
	return credits.filter(func(c): return c.role == role)

func add_credit(role: String, name: String, contribution: String = "") -> void:
	var entry = CreditEntry.new(role, name, contribution)
	credits.append(entry)
	record_update("credit_added", name)
	emit_event("credit_added", name)

func get_credits_text() -> String:
	var text = "=== CREDITS ===\n\n"
	var current_role = ""
	for credit in credits:
		if credit.role != current_role:
			text += "\n[%s]\n" % credit.role
			current_role = credit.role
		if credit.contribution != "":
			text += "  %s - %s\n" % [credit.name, credit.contribution]
		else:
			text += "  %s\n" % credit.name
	return text

func has_viewed_credits() -> bool:
	return get_state("credits_viewed", false)

func record_credits_view_time(duration_ms: int) -> void:
	set_state("credits_view_time", duration_ms)
	emit_event("view_time_recorded", duration_ms)

func get_credits_view_time() -> int:
	return get_state("credits_view_time", 0)

func record_section_timing(section: String, duration_ms: int) -> void:
	var timings = get_state("section_timing", {})
	timings[section] = duration_ms
	set_state("section_timing", timings)
	credit_section_reached.emit(section)

func mark_credits_skipped() -> void:
	set_state("credits_skipped", true)
	emit_event("credits_skipped", "")

func was_credits_skipped() -> bool:
	return get_state("credits_skipped", false)

func set_contribution_points(name: String, points: float) -> void:
	var contributions = get_state("contribution_points", {})
	contributions[name] = points
	set_state("contribution_points", contributions)

func get_contribution_points(name: String) -> float:
	var contributions = get_state("contribution_points", {})
	return contributions.get(name, 0.0)

func record_credit_performance(role: String, display_time: int) -> void:
	var perf = get_state("credit_performance", [])
	perf.append({"role": role, "display_time": display_time, "time": Time.get_ticks_msec()})
	if perf.size() > 100:
		perf.pop_front()
	set_state("credit_performance", perf)

func add_special_tribute(name: String, tribute_text: String) -> void:
	var tributes = get_state("special_tributes", [])
	tributes.append({"name": name, "text": tribute_text, "time": Time.get_ticks_msec()})
	set_state("special_tributes", tributes)
	emit_event("tribute_added", name)

func get_special_tributes() -> Array:
	return get_state("special_tributes", [])

func update_credits_statistics() -> void:
	var stats = get_state("credits_statistics", {})
	stats["total_credits"] = credits.size()
	stats["view_time"] = get_credits_view_time()
	stats["was_skipped"] = was_credits_skipped()
	stats["special_tributes"] = get_state("special_tributes", []).size()
	stats["update_events"] = get_state("credits_update_history", []).size()
	stats["performance_entries"] = get_state("credit_performance", []).size()
	stats["contributors_tracked"] = get_state("contribution_points", {}).size()
	stats["sections_timed"] = get_state("section_timing", {}).size()
	set_state("credits_statistics", stats)

func get_credits_statistics() -> Dictionary:
	update_credits_statistics()
	return get_state("credits_statistics", {})

func record_update(update_type: String, detail: String) -> void:
	var history = get_state("credits_update_history", [])
	history.append({"type": update_type, "detail": detail, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("credits_update_history", history)

func get_section_timing(section: String) -> int:
	var timings = get_state("section_timing", {})
	return timings.get(section, 0)
