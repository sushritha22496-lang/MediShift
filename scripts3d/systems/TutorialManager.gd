extends Node

class_name TutorialManager

enum TutorialStep {
	INTRO,
	MOVEMENT,
	CALLING,
	DETECTION,
	MEETING,
	TEAM_BUILDING,
	COMBAT,
	COMPLETE
}

var current_step: TutorialStep = TutorialStep.INTRO
var completed_steps: Array[TutorialStep] = []
var enabled: bool = true

signal step_changed(step: TutorialStep)
signal step_completed(step: TutorialStep)
signal tutorial_complete

func _ready() -> void:
	add_to_group("tutorial")

func advance_step() -> void:
	if current_step < TutorialStep.COMPLETE:
		completed_steps.append(current_step)
		current_step = current_step + 1
		step_completed.emit(completed_steps[-1])
		step_changed.emit(current_step)

		if current_step == TutorialStep.COMPLETE:
			tutorial_complete.emit()

func get_step_hint() -> String:
	match current_step:
		TutorialStep.INTRO: return "Welcome to Ramayana Quest! Help Rama find Sita."
		TutorialStep.MOVEMENT: return "Use WASD to move. Look around with the mouse."
		TutorialStep.CALLING: return "Press SPACE to call for help."
		TutorialStep.DETECTION: return "Hanuman will hear your calls within range."
		TutorialStep.MEETING: return "Get close to Hanuman and he will come to meet you."
		TutorialStep.TEAM_BUILDING: return "Gather monkeys to form a strong team."
		TutorialStep.COMBAT: return "Prepare for battles in Lanka."
		TutorialStep.COMPLETE: return "Tutorial complete!"
	return ""

func is_complete() -> bool:
	return current_step == TutorialStep.COMPLETE

func skip_tutorial() -> void:
	current_step = TutorialStep.COMPLETE
	tutorial_complete.emit()
