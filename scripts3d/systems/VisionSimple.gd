extends BaseSystemSimple

class_name VisionSimple

class Vision:
	var id: String
	var title: String
	var description: String
	var vision_type: String
	var progress: int
	var target: int
	func _init(p_id: String, p_title: String, p_desc: String, p_type: String, p_target: int = 1) -> void:
		id = p_id
		title = p_title
		description = p_desc
		vision_type = p_type
		progress = 0
		target = p_target

var visions: Array[Vision] = []

signal vision_triggered(vision: Vision)
signal vision_progressed(vision_id: String, progress: int)
signal vision_completed(vision_id: String)

func _ready() -> void:
	set_state("active_visions", [])
	set_state("completed_visions", [])
	set_state("vision_interpretations", {})
	set_state("vision_clarity_levels", {})
	set_state("vision_side_effects", {})
	set_state("vision_type_affinity", {})
	set_state("prophecy_fulfillment", {})
	set_state("vision_recall_events", [])
	set_state("vision_failure_consequences", [])
	set_state("vision_streak", 0)
	_initialize_visions()

func _initialize_visions() -> void:
	visions = [
		Vision.new("v1", "Sita's Call", "A vision of Sita calling for help", "prophecy", 3),
		Vision.new("v2", "The Demon King", "A vision of Ravana's darkness", "warning", 5),
		Vision.new("v3", "Divine Guidance", "Blessings from the gods", "blessing", 2),
		Vision.new("v4", "Path Forward", "Insight about the journey ahead", "insight", 4),
		Vision.new("v5", "Sacrifice and Salvation", "Understanding the quest's true cost", "revelation", 6)
	]

func trigger_vision(vision_id: String) -> bool:
	var vision = _get_vision(vision_id)
	if vision:
		var active = get_state("active_visions", [])
		if vision_id not in active:
			active.append(vision_id)
			set_state("active_visions", active)
		vision_triggered.emit(vision)
		emit_event("vision_triggered", vision_id)
		return true
	return false

func progress_vision(vision_id: String) -> void:
	var vision = _get_vision(vision_id)
	if vision:
		vision.progress += 1
		vision_progressed.emit(vision_id, vision.progress)
		emit_event("vision_progressed", vision_id)
		if vision.progress >= vision.target:
			complete_vision(vision_id)

func complete_vision(vision_id: String) -> void:
	var vision = _get_vision(vision_id)
	if vision:
		var active = get_state("active_visions", [])
		active.erase(vision_id)
		var completed = get_state("completed_visions", [])
		completed.append(vision_id)
		set_state("active_visions", active)
		set_state("completed_visions", completed)
		vision_completed.emit(vision_id)
		emit_event("vision_completed", vision_id)

func get_vision(vision_id: String) -> Vision:
	return _get_vision(vision_id)

func get_active_visions() -> Array[Vision]:
	var active_ids = get_state("active_visions", [])
	var active: Array[Vision] = []
	for v in visions:
		if v.id in active_ids:
			active.append(v)
	return active

func get_completed_visions() -> Array[Vision]:
	var completed_ids = get_state("completed_visions", [])
	var completed: Array[Vision] = []
	for v in visions:
		if v.id in completed_ids:
			completed.append(v)
	return completed

func get_vision_text() -> String:
	var active = get_active_visions()
	var completed = get_completed_visions()
	var text = "Visions: %d active | %d completed\n" % [active.size(), completed.size()]
	for vision in active:
		text += "✧ %s (%d/%d)\n" % [vision.title, vision.progress, vision.target]
	return text

func _get_vision(vision_id: String) -> Vision:
	for vision in visions:
		if vision.id == vision_id:
			return vision
	return null

func set_vision_clarity(vision_id: String, clarity: float) -> void:
	var levels = get_state("vision_clarity_levels", {})
	levels[vision_id] = clampf(clarity, 0.0, 1.0)
	set_state("vision_clarity_levels", levels)
	emit_event("clarity_set", vision_id)

func add_vision_interpretation(vision_id: String, interpretation: String) -> void:
	var interpretations = get_state("vision_interpretations", {})
	if vision_id not in interpretations:
		interpretations[vision_id] = []
	interpretations[vision_id].append(interpretation)
	set_state("vision_interpretations", interpretations)
	emit_event("interpretation_added", vision_id)

func apply_vision_side_effect(vision_id: String, effect: String) -> void:
	var effects = get_state("vision_side_effects", {})
	if vision_id not in effects:
		effects[vision_id] = []
	effects[vision_id].append(effect)
	set_state("vision_side_effects", effects)
	emit_event("side_effect_applied", vision_id)

func track_vision_type_affinity(vision_type: String) -> void:
	var affinity = get_state("vision_type_affinity", {})
	affinity[vision_type] = affinity.get(vision_type, 0) + 1
	set_state("vision_type_affinity", affinity)
	var streak = get_state("vision_streak", 0)
	set_state("vision_streak", streak + 1)
	emit_event("affinity_increased", vision_type)

func record_prophecy_fulfillment(vision_id: String, fulfilled: bool) -> void:
	var fulfillment = get_state("prophecy_fulfillment", {})
	fulfillment[vision_id] = {"fulfilled": fulfilled, "time": Time.get_ticks_msec()}
	set_state("prophecy_fulfillment", fulfillment)
	emit_event("prophecy_checked", vision_id)

func record_vision_recall(recall_data: Dictionary) -> void:
	var recalls = get_state("vision_recall_events", [])
	recalls.append({"data": recall_data, "timestamp": Time.get_ticks_msec()})
	if recalls.size() > 50:
		recalls.pop_front()
	set_state("vision_recall_events", recalls)
	emit_event("vision_recalled", recall_data)

func record_failure_consequence(consequence: String) -> void:
	var consequences = get_state("vision_failure_consequences", [])
	consequences.append(consequence)
	if consequences.size() > 20:
		consequences.pop_front()
	set_state("vision_failure_consequences", consequences)
	set_state("vision_streak", 0)
	emit_event("failure_recorded", consequence)

func get_vision_clarity(vision_id: String) -> float:
	var levels = get_state("vision_clarity_levels", {})
	return levels.get(vision_id, 0.5)

func get_dominant_vision_type() -> String:
	var affinity = get_state("vision_type_affinity", {})
	if affinity.is_empty():
		return ""
	var max_type = ""
	var max_count = 0
	for vtype in affinity:
		if affinity[vtype] > max_count:
			max_count = affinity[vtype]
			max_type = vtype
	return max_type

func get_fulfillment_rate() -> float:
	var fulfillment = get_state("prophecy_fulfillment", {})
	if fulfillment.is_empty():
		return 0.0
	var fulfilled = 0
	for v_id in fulfillment:
		if fulfillment[v_id]["fulfilled"]:
			fulfilled += 1
	return float(fulfilled) / float(fulfillment.size())
