extends BaseSystemSimple

class_name TutorialSimple

class TutorialStep:
	var id: String
	var title: String
	var instruction: String
	var target_action: String
	var completed: bool
	func _init(p_id: String, p_title: String, p_instr: String, p_action: String) -> void:
		id = p_id
		title = p_title
		instruction = p_instr
		target_action = p_action
		completed = false

var tutorial_steps: Array[TutorialStep] = []

signal step_started(step: TutorialStep)
signal step_completed(step_id: String)
signal tutorial_completed
signal tutorial_skipped

func _ready() -> void:
	set_state("current_step", 0)
	set_state("tutorial_completed_flag", false)
	set_state("skip_tutorial", false)
	set_state("step_times", {})
	set_state("hints_used", {})
	_initialize_tutorial()

func _initialize_tutorial() -> void:
	tutorial_steps = [
		TutorialStep.new("t1", "Welcome", "Welcome to the Ramayana Quest!", "acknowledge"),
		TutorialStep.new("t2", "Movement", "Use WASD keys to move around", "move"),
		TutorialStep.new("t3", "Combat", "Press Space to attack enemies", "attack"),
		TutorialStep.new("t4", "Inventory", "Press I to open your inventory", "open_inventory"),
		TutorialStep.new("t5", "Quest Log", "Press Q to view your quests", "open_quests"),
		TutorialStep.new("t6", "Save Game", "Press Ctrl+S to save your progress", "save")
	]

func start_tutorial() -> void:
	if not get_state("skip_tutorial", false):
		set_state("current_step", 0)
		_show_current_step()

func _show_current_step() -> void:
	var step_idx = get_state("current_step", 0)
	if step_idx < tutorial_steps.size():
		var step = tutorial_steps[step_idx]
		step_started.emit(step)
		emit_event("step_started", step.id)

func complete_current_step() -> void:
	var step_idx = get_state("current_step", 0)
	if step_idx < tutorial_steps.size():
		var step = tutorial_steps[step_idx]
		step.completed = true
		step_completed.emit(step.id)
		emit_event("step_completed", step.id)

		step_idx += 1
		set_state("current_step", step_idx)

		if step_idx >= tutorial_steps.size():
			set_state("tutorial_completed_flag", true)
			tutorial_completed.emit()
			emit_event("tutorial_completed", "")
		else:
			_show_current_step()

func skip_tutorial() -> void:
	set_state("skip_tutorial", true)
	tutorial_skipped.emit()
	emit_event("tutorial_skipped", "")

func get_current_step() -> TutorialStep:
	var step_idx = get_state("current_step", 0)
	if step_idx < tutorial_steps.size():
		return tutorial_steps[step_idx]
	return null

func is_tutorial_completed() -> bool:
	return get_state("tutorial_completed_flag", false)

func get_tutorial_progress() -> float:
	var current = get_state("current_step", 0)
	return (float(current) / float(tutorial_steps.size())) * 100.0

func get_tutorial_text() -> String:
	var step = get_current_step()
	if not step:
		return "Tutorial completed!"
	return "Step %d/%d: %s\n%s" % [get_state("current_step", 0) + 1, tutorial_steps.size(), step.title, step.instruction]

func record_step_start_time(step_id: String) -> void:
	var times = get_state("step_times", {})
	if step_id not in times:
		times[step_id] = {"start": Time.get_ticks_msec(), "end": 0}
	set_state("step_times", times)

func record_step_end_time(step_id: String) -> float:
	var times = get_state("step_times", {})
	if step_id in times:
		times[step_id]["end"] = Time.get_ticks_msec()
		var duration = (times[step_id]["end"] - times[step_id]["start"]) / 1000.0
		set_state("step_times", times)
		return duration
	return 0.0

func use_hint(step_id: String) -> void:
	var hints = get_state("hints_used", {})
	hints[step_id] = hints.get(step_id, 0) + 1
	set_state("hints_used", hints)

func get_step_completion_time(step_id: String) -> float:
	var times = get_state("step_times", {})
	if step_id in times and times[step_id]["end"] > 0:
		return (times[step_id]["end"] - times[step_id]["start"]) / 1000.0
	return 0.0
