extends BaseSystemSimple

class_name AcademySimple

class Lesson:
	var id: String
	var name: String
	var instructor: String
	var cost: float
	var skill_reward: String
	var duration: int
	var level: int
	var proficiency_gain: float
	var prerequisites: Array[String]
	var difficulty: int
	var instructor_affection: float
	func _init(p_id: String, p_name: String, p_inst: String, p_cost: float, p_skill: String, p_dur: int, p_level: int = 1) -> void:
		id = p_id
		name = p_name
		instructor = p_inst
		cost = p_cost
		skill_reward = p_skill
		duration = p_dur
		level = p_level
		proficiency_gain = 5.0 + (p_level * 2.0)
		prerequisites = []
		difficulty = p_level
		instructor_affection = 0.0

var lessons: Array[Lesson] = []

signal lesson_started(lesson: Lesson)
signal lesson_completed(lesson_id: String, skill: String)

func _ready() -> void:
	set_state("completed_lessons", [])
	set_state("current_lesson", "")
	_initialize_lessons()

func _initialize_lessons() -> void:
	lessons = [
		Lesson.new("l1", "Sword Mastery", "Warrior Master", 100.0, "sword_slash", 30, 1),
		Lesson.new("l2", "Archery Basics", "Archer Guide", 75.0, "rapid_shot", 25, 1),
		Lesson.new("l3", "Magic Fundamentals", "Mage Sage", 150.0, "fireball", 40, 2),
		Lesson.new("l4", "Stealth Training", "Shadow Ranger", 120.0, "invisibility", 35, 2),
		Lesson.new("l5", "Healing Arts", "Priest Oracle", 80.0, "heal_ally", 28, 1)
	]
	lessons[2].prerequisites = ["l1"]
	lessons[3].prerequisites = ["l2"]
	lessons[4].prerequisites = ["l3"]
	set_state("lesson_proficiency", {})
	set_state("practice_sessions", {})
	set_state("instructor_reputation", {})
	set_state("student_performance_history", [])
	set_state("mastery_levels", {})
	set_state("lesson_attempt_count", {})
	set_state("skill_combination_bonuses", {})
	set_state("exam_scores", {})

func start_lesson(lesson_id: String) -> bool:
	var lesson = _get_lesson(lesson_id)
	if lesson and lesson_id not in get_state("completed_lessons", []):
		if not _check_prerequisites(lesson_id):
			return false
		set_state("current_lesson", lesson_id)
		lesson_started.emit(lesson)
		emit_event("lesson_started", lesson_id)
		return true
	return false

func _check_prerequisites(lesson_id: String) -> bool:
	var lesson = _get_lesson(lesson_id)
	if not lesson:
		return false
	var completed = get_state("completed_lessons", [])
	for prereq in lesson.prerequisites:
		if prereq not in completed:
			return false
	return true

func complete_lesson(lesson_id: String, performance: float = 1.0) -> String:
	var lesson = _get_lesson(lesson_id)
	if lesson:
		var completed = get_state("completed_lessons", [])
		completed.append(lesson_id)
		set_state("completed_lessons", completed)
		var proficiency = get_state("lesson_proficiency", {})
		proficiency[lesson.skill_reward] = lesson.proficiency_gain * performance
		set_state("lesson_proficiency", proficiency)
		set_state("current_lesson", "")
		lesson.instructor_affection += 10.0 * performance
		lesson_completed.emit(lesson_id, lesson.skill_reward)
		emit_event("lesson_completed", {"lesson": lesson_id, "performance": performance})
		return lesson.skill_reward
	return ""

func practice_skill(skill_id: String) -> float:
	var proficiency = get_state("lesson_proficiency", {})
	if skill_id in proficiency:
		var gain = randf_range(1.0, 3.0)
		proficiency[skill_id] += gain
		set_state("lesson_proficiency", proficiency)
		emit_event("skill_practiced", skill_id)
		return proficiency[skill_id]
	return 0.0

func get_skill_proficiency(skill_id: String) -> float:
	var proficiency = get_state("lesson_proficiency", {})
	return proficiency.get(skill_id, 0.0)

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

func record_lesson_attempt(lesson_id: String) -> void:
	var attempts = get_state("lesson_attempt_count", {})
	attempts[lesson_id] = attempts.get(lesson_id, 0) + 1
	set_state("lesson_attempt_count", attempts)

func update_instructor_reputation(instructor_name: String, change: float) -> void:
	var reputation = get_state("instructor_reputation", {})
	reputation[instructor_name] = reputation.get(instructor_name, 0.0) + change
	set_state("instructor_reputation", reputation)
	emit_event("instructor_reputation_changed", instructor_name)

func record_performance_history(lesson_id: String, performance: float) -> void:
	var history = get_state("student_performance_history", [])
	history.append({"lesson": lesson_id, "performance": performance, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("student_performance_history", history)

func set_mastery_level(skill_id: String, level: int) -> void:
	var mastery = get_state("mastery_levels", {})
	mastery[skill_id] = level
	set_state("mastery_levels", mastery)
	emit_event("mastery_level_set", skill_id)

func get_mastery_level(skill_id: String) -> int:
	var mastery = get_state("mastery_levels", {})
	return mastery.get(skill_id, 0)

func apply_skill_combination_bonus(skill1: String, skill2: String, bonus: float) -> void:
	var bonuses = get_state("skill_combination_bonuses", {})
	var key = "%s_%s" % [minf(skill1, skill2), maxf(skill1, skill2)]
	bonuses[key] = bonus
	set_state("skill_combination_bonuses", bonuses)

func get_combination_bonus(skill1: String, skill2: String) -> float:
	var bonuses = get_state("skill_combination_bonuses", {})
	var key = "%s_%s" % [minf(skill1, skill2), maxf(skill1, skill2)]
	return bonuses.get(key, 0.0)

func record_exam_score(exam_name: String, score: float) -> void:
	var scores = get_state("exam_scores", {})
	scores[exam_name] = score
	set_state("exam_scores", scores)
	emit_event("exam_completed", exam_name)

func get_exam_score(exam_name: String) -> float:
	var scores = get_state("exam_scores", {})
	return scores.get(exam_name, 0.0)

func get_instructor_reputation(instructor_name: String) -> float:
	var reputation = get_state("instructor_reputation", {})
	return reputation.get(instructor_name, 0.0)

func get_average_performance() -> float:
	var history = get_state("student_performance_history", [])
	if history.is_empty():
		return 0.0
	var total = history.reduce(func(acc, entry): return acc + entry["performance"], 0.0)
	return total / float(history.size())

func record_lesson_attempt(lesson_id: String) -> void:
	var attempts = get_state("lesson_attempt_count", {})
	attempts[lesson_id] = attempts.get(lesson_id, 0) + 1
	set_state("lesson_attempt_count", attempts)

func update_instructor_reputation(instructor_name: String, change: float) -> void:
	var reputation = get_state("instructor_reputation", {})
	reputation[instructor_name] = reputation.get(instructor_name, 0.0) + change
	set_state("instructor_reputation", reputation)
	emit_event("instructor_reputation_changed", instructor_name)

func record_performance_history(lesson_id: String, performance: float) -> void:
	var history = get_state("student_performance_history", [])
	history.append({"lesson": lesson_id, "performance": performance, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("student_performance_history", history)

func set_mastery_level(skill_id: String, level: int) -> void:
	var mastery = get_state("mastery_levels", {})
	mastery[skill_id] = level
	set_state("mastery_levels", mastery)
	emit_event("mastery_level_set", skill_id)

func get_mastery_level(skill_id: String) -> int:
	var mastery = get_state("mastery_levels", {})
	return mastery.get(skill_id, 0)

func apply_skill_combination_bonus(skill1: String, skill2: String, bonus: float) -> void:
	var bonuses = get_state("skill_combination_bonuses", {})
	var key = "%s_%s" % [minf(skill1, skill2), maxf(skill1, skill2)]
	bonuses[key] = bonus
	set_state("skill_combination_bonuses", bonuses)

func get_combination_bonus(skill1: String, skill2: String) -> float:
	var bonuses = get_state("skill_combination_bonuses", {})
	var key = "%s_%s" % [minf(skill1, skill2), maxf(skill1, skill2)]
	return bonuses.get(key, 0.0)

func record_exam_score(exam_name: String, score: float) -> void:
	var scores = get_state("exam_scores", {})
	scores[exam_name] = score
	set_state("exam_scores", scores)
	emit_event("exam_completed", exam_name)

func get_exam_score(exam_name: String) -> float:
	var scores = get_state("exam_scores", {})
	return scores.get(exam_name, 0.0)

func get_instructor_reputation(instructor_name: String) -> float:
	var reputation = get_state("instructor_reputation", {})
	return reputation.get(instructor_name, 0.0)

func get_average_performance() -> float:
	var history = get_state("student_performance_history", [])
	if history.is_empty():
		return 0.0
	var total = history.reduce(func(acc, entry): return acc + entry["performance"], 0.0)
	return total / float(history.size())
