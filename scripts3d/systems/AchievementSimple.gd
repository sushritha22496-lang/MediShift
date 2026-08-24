extends Node

class_name AchievementSimple

class Achievement:
	var id: String
	var name: String
	var description: String
	var unlocked: bool = false

	func _init(p_id: String, p_name: String, p_desc: String) -> void:
		id = p_id
		name = p_name
		description = p_desc

var achievements: Array[Achievement] = []
var unlocked_achievements: Array[Achievement] = []

signal achievement_unlocked(achievement: Achievement)

func _ready() -> void:
	_initialize_achievements()

func _initialize_achievements() -> void:
	var ach1 = Achievement.new("first_steps", "First Steps", "Move for the first time")
	var ach2 = Achievement.new("meet_hanuman", "Meet Hanuman", "Complete the first encounter")
	var ach3 = Achievement.new("gatherer", "Gatherer", "Collect 10 items")
	var ach4 = Achievement.new("warrior", "Warrior", "Defeat 5 enemies")
	var ach5 = Achievement.new("merchant", "Trader", "Buy and sell items")
	var ach6 = Achievement.new("explorer", "Explorer", "Visit all locations")
	var ach7 = Achievement.new("legend", "Legend", "Reach level 10")
	var ach8 = Achievement.new("rich", "Rich", "Accumulate 1000 gold")

	achievements = [ach1, ach2, ach3, ach4, ach5, ach6, ach7, ach8]

func unlock_achievement(ach_id: String) -> bool:
	for ach in achievements:
		if ach.id == ach_id and not ach.unlocked:
			ach.unlocked = true
			unlocked_achievements.append(ach)
			achievement_unlocked.emit(ach)
			print("🏆 Achievement Unlocked: %s" % ach.name)
			return true
	return false

func is_achievement_unlocked(ach_id: String) -> bool:
	for ach in unlocked_achievements:
		if ach.id == ach_id:
			return true
	return false

func get_achievement(ach_id: String) -> Achievement:
	for ach in achievements:
		if ach.id == ach_id:
			return ach
	return null

func get_achievements_text() -> String:
	var text = "Achievements [%d/%d]:\n" % [unlocked_achievements.size(), achievements.size()]
	for ach in achievements:
		var status = "✓" if ach.unlocked else "✗"
		text += "%s %s\n" % [status, ach.name]
	return text

func get_progress() -> float:
	if achievements.is_empty():
		return 0.0
	return float(unlocked_achievements.size()) / float(achievements.size())
