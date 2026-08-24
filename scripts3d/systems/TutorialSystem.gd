extends CanvasLayer

class_name TutorialSystem

class TutorialStep:
	var id: String
	var title: String
	var description: String
	var position: Vector2 = Vector2.ZERO
	var target_action: String = ""
	var completed: bool = false

var tutorial_steps: Array[TutorialStep] = []
var current_step_index: int = 0
var tutorial_active: bool = false

var tutorial_label: Label
var progress_label: Label

signal tutorial_started
signal tutorial_step_completed(step: TutorialStep)
signal tutorial_finished

func _ready() -> void:
	_create_tutorial_ui()
	_initialize_steps()

func _create_tutorial_ui() -> void:
	tutorial_label = Label.new()
	tutorial_label.add_theme_font_size_override("font_sizes", 18)
	tutorial_label.set_anchors_preset(Control.PRESET_CENTER)
	tutorial_label.custom_minimum_size = Vector2(600, 150)
	add_child(tutorial_label)

	progress_label = Label.new()
	progress_label.add_theme_font_size_override("font_sizes", 14)
	progress_label.set_anchors_preset(Control.PRESET_BOTTOM_CENTER)
	progress_label.offset_top = -50
	add_child(progress_label)

func _initialize_steps() -> void:
	var step1 = TutorialStep.new()
	step1.id = "movement"
	step1.title = "Movement"
	step1.description = "Use WASD to move through the forest\nHold Shift to run faster"
	step1.target_action = "move"

	var step2 = TutorialStep.new()
	step2.id = "calling"
	step2.title = "Calling for Sita"
	step2.description = "Press SPACE to call for Sita\nThis will attract NPCs in the area"
	step2.target_action = "call"

	var step3 = TutorialStep.new()
	step3.id = "interaction"
	step3.title = "Interaction"
	step3.description = "Press E near NPCs to interact\nYou can talk or trade with them"
	step3.target_action = "interact"

	var step4 = TutorialStep.new()
	step4.id = "inventory"
	step4.title = "Inventory"
	step4.description = "Press I to open your inventory\nCollect items throughout the world"
	step4.target_action = "inventory"

	tutorial_steps = [step1, step2, step3, step4]

func start_tutorial() -> void:
	tutorial_active = true
	current_step_index = 0
	tutorial_started.emit()
	_show_current_step()

func _show_current_step() -> void:
	if current_step_index >= tutorial_steps.size():
		finish_tutorial()
		return

	var step = tutorial_steps[current_step_index]
	tutorial_label.text = "%s\n\n%s" % [step.title, step.description]
	_update_progress()

func complete_current_step() -> void:
	if current_step_index < tutorial_steps.size():
		var step = tutorial_steps[current_step_index]
		step.completed = true
		tutorial_step_completed.emit(step)

	current_step_index += 1
	_show_current_step()

func finish_tutorial() -> void:
	tutorial_active = false
	tutorial_label.text = "Tutorial Complete!\nYou're ready to explore the world!"
	progress_label.text = ""
	await get_tree().create_timer(3.0).timeout
	tutorial_label.text = ""
	tutorial_finished.emit()

func _update_progress() -> void:
	var progress = (current_step_index + 1)
	var total = tutorial_steps.size()
	progress_label.text = "Step %d / %d" % [progress, total]

func skip_tutorial() -> void:
	tutorial_active = false
	tutorial_label.text = ""
	progress_label.text = ""

func is_tutorial_active() -> bool:
	return tutorial_active

func get_current_step() -> TutorialStep:
	if current_step_index < tutorial_steps.size():
		return tutorial_steps[current_step_index]
	return null
