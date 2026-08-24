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
