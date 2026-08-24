extends BaseSystemSimple

class_name AcademySimple

class Lesson:
	var id: String
	var name: String
	var instructor: String
	var cost: float
	var skill_reward: String
	var duration: int
	func _init(p_id: String, p_name: String, p_inst: String, p_cost: float, p_skill: String, p_dur: int) -> void:
		id = p_id
		name = p_name
		instructor = p_inst
		cost = p_cost
		skill_reward = p_skill
		duration = p_dur

var lessons: Array[Lesson] = []

signal lesson_started(lesson: Lesson)
signal lesson_completed(lesson_id: String, skill: String)

func _ready() -> void:
	set_state("completed_lessons", [])
	set_state("current_lesson", "")
	_initialize_lessons()

func _initialize_lessons() -> void:
	lessons = [
		Lesson.new("l1", "Sword Mastery", "Warrior Master", 100.0, "sword_slash", 30),
		Lesson.new("l2", "Archery Basics", "Archer Guide", 75.0, "rapid_shot", 25),
		Lesson.new("l3", "Magic Fundamentals", "Mage Sage", 150.0, "fireball", 40),
		Lesson.new("l4", "Stealth Training", "Shadow Ranger", 120.0, "invisibility", 35),
		Lesson.new("l5", "Healing Arts", "Priest Oracle", 80.0, "heal_ally", 28)
	]

func start_lesson(lesson_id: String) -> bool:
	var lesson = _get_lesson(lesson_id)
	if lesson and lesson_id not in get_state("completed_lessons", []):
		set_state("current_lesson", lesson_id)
		lesson_started.emit(lesson)
		emit_event("lesson_started", lesson_id)
		return true
	return false

func complete_lesson(lesson_id: String) -> String:
	var lesson = _get_lesson(lesson_id)
	if lesson:
		var completed = get_state("completed_lessons", [])
		completed.append(lesson_id)
		set_state("completed_lessons", completed)
		set_state("current_lesson", "")
		lesson_completed.emit(lesson_id, lesson.skill_reward)
		emit_event("lesson_completed", lesson_id)
		return lesson.skill_reward
	return ""

func get_lesson(lesson_id: String) -> Lesson:
	return _get_lesson(lesson_id)

func get_available_lessons() -> Array[Lesson]:
	var completed = get_state("completed_lessons", [])
	return lessons.filter(func(l): return l.id not in completed)

func get_completed_lessons() -> Array[Lesson]:
	var completed_ids = get_state("completed_lessons", [])
	var completed: Array[Lesson] = []
	for l in lessons:
		if l.id in completed_ids:
			completed.append(l)
	return completed

func get_academy_text() -> String:
	var completed = get_completed_lessons()
	var available = get_available_lessons()
	var text = "Academy\nCompleted: %d | Available: %d\n" % [completed.size(), available.size()]
	for lesson in available.slice(0, 3):
		text += "%s - %.0f gold\n" % [lesson.name, lesson.cost]
	return text

func _get_lesson(lesson_id: String) -> Lesson:
	for lesson in lessons:
		if lesson.id == lesson_id:
			return lesson
	return null
