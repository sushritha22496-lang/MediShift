extends BaseSystemSimple

class_name NPCScheduleSimple

class ScheduleEntry:
	var time: int
	var location: String
	var activity: String
	func _init(p_time: int, p_loc: String, p_activity: String) -> void:
		time = p_time
		location = p_loc
		activity = p_activity

var npc_schedules: Dictionary = {}

signal npc_activity_changed(npc_id: String, activity: String)
signal npc_moved(npc_id: String, location: String)

func _ready() -> void:
	set_state("current_activities", {})
	set_state("npc_moods", {})
	set_state("schedule_deviations", [])
	set_state("location_preferences", {})
	set_state("activity_patterns", {})
	set_state("routine_efficiency", {})
	set_state("schedule_modifications", [])
	set_state("routine_interruptions", [])
	_initialize_schedules()

func _initialize_schedules() -> void:
	npc_schedules["hanuman"] = [
		ScheduleEntry.new(6, "forest_center", "sleeping"),
		ScheduleEntry.new(8, "forest_clearing", "patrolling"),
		ScheduleEntry.new(12, "shrine", "praying"),
		ScheduleEntry.new(18, "tavern", "resting"),
		ScheduleEntry.new(22, "forest_center", "sleeping")
	]
	npc_schedules["merchant"] = [
		ScheduleEntry.new(6, "home", "sleeping"),
		ScheduleEntry.new(8, "market", "selling"),
		ScheduleEntry.new(12, "tavern", "eating"),
		ScheduleEntry.new(14, "market", "selling"),
		ScheduleEntry.new(20, "home", "sleeping")
	]
	npc_schedules["sage"] = [
		ScheduleEntry.new(6, "temple", "meditating"),
		ScheduleEntry.new(12, "library", "studying"),
		ScheduleEntry.new(18, "temple", "teaching"),
		ScheduleEntry.new(22, "home", "sleeping")
	]

func update_schedules(current_hour: int) -> void:
	for npc_id in npc_schedules.keys():
		var schedule = npc_schedules[npc_id]
		var current_activity = _get_activity_for_hour(schedule, current_hour)
		var activities = get_state("current_activities", {})
		var prev_activity = activities.get(npc_id, "")
		if prev_activity != current_activity:
			activities[npc_id] = current_activity
			set_state("current_activities", activities)
			npc_activity_changed.emit(npc_id, current_activity)
			emit_event("npc_activity_changed", npc_id)

func get_npc_activity(npc_id: String, hour: int = -1) -> String:
	if hour == -1:
		var activities = get_state("current_activities", {})
		return activities.get(npc_id, "unknown")
	var schedule = npc_schedules.get(npc_id, [])
	return _get_activity_for_hour(schedule, hour)

func get_npc_location(npc_id: String, hour: int = -1) -> String:
	var schedule = npc_schedules.get(npc_id, [])
	if schedule.is_empty():
		return "unknown"
	var entry = _get_entry_for_hour(schedule, hour if hour >= 0 else 12)
	return entry.location if entry else "unknown"

func add_npc_schedule(npc_id: String, schedule: Array[ScheduleEntry]) -> void:
	npc_schedules[npc_id] = schedule
	emit_event("schedule_added", npc_id)

func get_schedule_text(npc_id: String) -> String:
	var schedule = npc_schedules.get(npc_id, [])
	if schedule.is_empty():
		return "%s has no schedule" % npc_id
	var text = "%s Schedule:\n" % npc_id.capitalize()
	for entry in schedule:
		text += "%02d:00 - %s at %s\n" % [entry.time, entry.activity, entry.location]
	return text

func _get_activity_for_hour(schedule: Array[ScheduleEntry], hour: int) -> String:
	var entry = _get_entry_for_hour(schedule, hour)
	return entry.activity if entry else "unknown"

func _get_entry_for_hour(schedule: Array[ScheduleEntry], hour: int) -> ScheduleEntry:
	var best_entry: ScheduleEntry = schedule[0] if schedule.size() > 0 else null
	for entry in schedule:
		if entry.time <= hour:
			best_entry = entry
		else:
			break
	return best_entry

func set_npc_mood(npc_id: String, mood: String) -> void:
	var moods = get_state("npc_moods", {})
	moods[npc_id] = mood
	set_state("npc_moods", moods)
	emit_event("mood_changed", npc_id)

func track_schedule_deviation(npc_id: String, deviation_reason: String) -> void:
	var deviations = get_state("schedule_deviations", [])
	deviations.append({"npc": npc_id, "reason": deviation_reason, "time": Time.get_ticks_msec()})
	if deviations.size() > 50:
		deviations.pop_front()
	set_state("schedule_deviations", deviations)
	emit_event("deviation_tracked", npc_id)

func record_location_preference(npc_id: String, location: String) -> void:
	var prefs = get_state("location_preferences", {})
	if npc_id not in prefs:
		prefs[npc_id] = {}
	prefs[npc_id][location] = prefs[npc_id].get(location, 0) + 1
	set_state("location_preferences", prefs)
	emit_event("preference_recorded", npc_id)

func record_activity_pattern(npc_id: String, activity: String) -> void:
	var patterns = get_state("activity_patterns", {})
	if npc_id not in patterns:
		patterns[npc_id] = []
	patterns[npc_id].append(activity)
	if patterns[npc_id].size() > 100:
		patterns[npc_id].pop_front()
	set_state("activity_patterns", patterns)

func calculate_routine_efficiency(npc_id: String) -> float:
	var deviations = get_state("schedule_deviations", [])
	var dev_count = 0
	for dev in deviations:
		if dev["npc"] == npc_id:
			dev_count += 1
	return maxf(0.0, 1.0 - (float(dev_count) * 0.05))

func record_routine_interruption(npc_id: String, interruption: String) -> void:
	var interrupts = get_state("routine_interruptions", [])
	interrupts.append({"npc": npc_id, "reason": interruption, "time": Time.get_ticks_msec()})
	if interrupts.size() > 30:
		interrupts.pop_front()
	set_state("routine_interruptions", interrupts)
	emit_event("routine_interrupted", npc_id)

func modify_npc_schedule(npc_id: String, new_schedule: Array[ScheduleEntry]) -> void:
	npc_schedules[npc_id] = new_schedule
	var mods = get_state("schedule_modifications", [])
	mods.append({"npc": npc_id, "time": Time.get_ticks_msec()})
	if mods.size() > 50:
		mods.pop_front()
	set_state("schedule_modifications", mods)
	emit_event("schedule_modified", npc_id)

func get_npc_mood(npc_id: String) -> String:
	var moods = get_state("npc_moods", {})
	return moods.get(npc_id, "neutral")

func get_most_preferred_location(npc_id: String) -> String:
	var prefs = get_state("location_preferences", {})
	if npc_id not in prefs or prefs[npc_id].is_empty():
		return ""
	var max_loc = ""
	var max_count = 0
	for loc in prefs[npc_id]:
		if prefs[npc_id][loc] > max_count:
			max_count = prefs[npc_id][loc]
			max_loc = loc
	return max_loc
