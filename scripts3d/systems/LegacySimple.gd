extends BaseSystemSimple

class_name LegacySimple

class Record:
	var id: String
	var title: String
	var description: String
	var value: float
	var timestamp: float
	func _init(p_id: String, p_title: String, p_desc: String, p_value: float) -> void:
		id = p_id
		title = p_title
		description = p_desc
		value = p_value
		timestamp = Time.get_ticks_msec()

var records: Array[Record] = []

signal record_created(record: Record)
signal milestone_reached(milestone: String)

func _ready() -> void:
	set_state("character_records", [])
	set_state("milestones_reached", [])
	set_state("record_history", [])
	set_state("milestone_tracking", [])
	set_state("legacy_statistics", {})
	set_state("value_progression", [])
	set_state("record_categories", {})

func create_record(title: String, description: String, value: float = 1.0) -> Record:
	var id = "rec_%d" % randi()
	var record = Record.new(id, title, description, value)
	records.append(record)
	var char_records = get_state("character_records", [])
	char_records.append({
		"title": title,
		"description": description,
		"value": value,
		"timestamp": record.timestamp
	})
	set_state("character_records", char_records)
	_record_history_entry(title, value)
	_track_value_progression()
	record_created.emit(record)
	emit_event("record_created", id)
	return record

func reach_milestone(milestone: String) -> void:
	var milestones = get_state("milestones_reached", [])
	if milestone not in milestones:
		milestones.append(milestone)
		set_state("milestones_reached", milestones)
		_record_milestone_tracking(milestone)
		milestone_reached.emit(milestone)
		emit_event("milestone_reached", milestone)

func get_all_records() -> Array[Record]:
	return records

func get_record_count() -> int:
	return records.size()

func get_milestones() -> Array:
	return get_state("milestones_reached", [])

func get_total_value() -> float:
	var total = 0.0
	for record in records:
		total += record.value
	return total

func get_legacy_text() -> String:
	var text = "Legacy\nRecords: %d | Milestones: %d\n" % [get_record_count(), get_milestones().size()]
	text += "Total Legacy Value: %.0f\n" % get_total_value()
	for record in records.slice(-3):
		text += "• %s (%.0f)\n" % [record.title, record.value]
	return text

func get_legacy_summary() -> String:
	var summary = "=== CHARACTER LEGACY ===\n"
	summary += "Records Created: %d\n" % get_record_count()
	summary += "Total Value: %.0f\n" % get_total_value()
	summary += "Milestones: %d\n\n" % get_milestones().size()
	for milestone in get_milestones().slice(-5):
		summary += "✓ %s\n" % milestone
	return summary

func _record_history_entry(title: String, value: float) -> void:
	var history = get_state("record_history", [])
	history.append({"title": title, "value": value, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("record_history", history)

func _record_milestone_tracking(milestone: String) -> void:
	var tracking = get_state("milestone_tracking", [])
	tracking.append({"milestone": milestone, "time": Time.get_ticks_msec()})
	if tracking.size() > 50:
		tracking.pop_front()
	set_state("milestone_tracking", tracking)

func _track_value_progression() -> void:
	var progression = get_state("value_progression", [])
	progression.append({"value": get_total_value(), "time": Time.get_ticks_msec()})
	if progression.size() > 50:
		progression.pop_front()
	set_state("value_progression", progression)

func categorize_record(record_title: String, category: String) -> void:
	var categories = get_state("record_categories", {})
	categories[record_title] = category
	set_state("record_categories", categories)

func get_records_by_category(category: String) -> Array:
	var categories = get_state("record_categories", {})
	var result = []
	for title in categories:
		if categories[title] == category:
			result.append(title)
	return result

func get_record_history() -> Array:
	return get_state("record_history", [])

func get_milestone_tracking() -> Array:
	return get_state("milestone_tracking", [])

func update_legacy_statistics() -> void:
	var stats = get_state("legacy_statistics", {})
	stats["records"] = get_record_count()
	stats["milestones"] = get_milestones().size()
	stats["total_value"] = get_total_value()
	stats["categories"] = get_state("record_categories", {}).size()
	set_state("legacy_statistics", stats)

func get_legacy_statistics() -> Dictionary:
	update_legacy_statistics()
	return get_state("legacy_statistics", {})
