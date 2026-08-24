extends Node

class_name TutorialSimple

class TutorialStep:
	var id: String
	var title: String
	var description: String
	var completed: bool = false

	func _init(p_id: String, p_title: String, p_desc: String) -> void:
		id = p_id
		title = p_title
		description = p_desc

var tutorial_steps: Array[TutorialStep] = []
var current_step_index: int = 0
var tutorial_enabled: bool = true

signal step_started(step: TutorialStep)
signal step_completed(step: TutorialStep)
signal tutorial_complete

func _ready() -> void:
	_initialize_steps()

func _initialize_steps() -> void:
	var step1 = TutorialStep.new("movement", "Move Rama", "Use WASD keys to move around the forest")
	var step2 = TutorialStep.new("sprint", "Sprint", "Hold Shift while moving to run faster")
	var step3 = TutorialStep.new("call", "Call Hanuman", "Press Space to call out for Sita")
	var step4 = TutorialStep.new("interact", "Interact", "Press E to interact with NPCs and objects")
	var step5 = TutorialStep.new("inventory", "Collect Items", "Gather items from the world")
	var step6 = TutorialStep.new("quest", "Complete Quests", "Follow quest objectives to progress")

	tutorial_steps = [step1, step2, step3, step4, step5, step6]

	if tutorial_steps.size() > 0:
		step_started.emit(tutorial_steps[0])

func complete_current_step() -> void:
	if current_step_index < tutorial_steps.size():
		tutorial_steps[current_step_index].completed = true
		step_completed.emit(tutorial_steps[current_step_index])

		current_step_index += 1
		if current_step_index >= tutorial_steps.size():
			tutorial_complete.emit()
			print("Tutorial Complete!")
		else:
			step_started.emit(tutorial_steps[current_step_index])

func skip_tutorial() -> void:
	for step in tutorial_steps:
		if not step.completed:
			step.completed = true
	tutorial_complete.emit()
	print("Tutorial skipped")

func get_current_step() -> TutorialStep:
	if current_step_index < tutorial_steps.size():
		return tutorial_steps[current_step_index]
	return null

func get_tutorial_text() -> String:
	if not tutorial_enabled or current_step_index >= tutorial_steps.size():
		return ""

	var step = tutorial_steps[current_step_index]
	return "📖 %s: %s" % [step.title, step.description]

func get_progress() -> float:
	if tutorial_steps.is_empty():
		return 0.0
	var completed = tutorial_steps.filter(func(s): return s.completed).size()
	return float(completed) / float(tutorial_steps.size())

func toggle_tutorial(enabled: bool) -> void:
	tutorial_enabled = enabled
