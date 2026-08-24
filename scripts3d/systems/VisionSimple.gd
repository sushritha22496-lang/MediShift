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
