extends Node3D

class_name AchievementSystem

class Achievement:
	var id: String
	var name: String
	var description: String
	var icon: String
	var points: int = 10
	var unlocked: bool = false
	var unlock_date: String = ""

var achievements: Dictionary = {}
var unlocked_achievements: Array[String] = []

signal achievement_unlocked(achievement: Achievement)
signal progress_updated(achievement_id: String, progress: int, target: int)

func _ready() -> void:
	_initialize_achievements()

func _initialize_achievements() -> void:
	var first_meeting = Achievement.new()
	first_meeting.id = "first_meeting"
	first_meeting.name = "First Meeting"
	first_meeting.description = "Meet Hanuman for the first time"
	first_meeting.points = 10

	var explorer = Achievement.new()
	explorer.id = "explorer"
	explorer.name = "Explorer"
	explorer.description = "Explore all locations"
	explorer.points = 25

	var collector = Achievement.new()
	collector.id = "collector"
	collector.name = "Collector"
	collector.description = "Collect 50 items"
	collector.points = 15

	var quest_master = Achievement.new()
	quest_master.id = "quest_master"
	quest_master.name = "Quest Master"
	quest_master.description = "Complete 10 quests"
	quest_master.points = 30

	var legendary = Achievement.new()
	legendary.id = "legendary"
	legendary.name = "Legendary Warrior"
	legendary.description = "Reach level 50"
	legendary.points = 50

	achievements["first_meeting"] = first_meeting
	achievements["explorer"] = explorer
	achievements["collector"] = collector
	achievements["quest_master"] = quest_master
	achievements["legendary"] = legendary

func unlock_achievement(achievement_id: String) -> bool:
	if not achievements.has(achievement_id):
		return false

	if achievement_id in unlocked_achievements:
		return false

	var achievement = achievements[achievement_id]
	achievement.unlocked = true
	achievement.unlock_date = Time.get_datetime_string_from_system()
	unlocked_achievements.append(achievement_id)

	achievement_unlocked.emit(achievement)
	return true

func is_unlocked(achievement_id: String) -> bool:
	return achievement_id in unlocked_achievements

func get_achievement(achievement_id: String) -> Achievement:
	return achievements.get(achievement_id, null)

func get_all_achievements() -> Array:
	return achievements.values()

func get_unlocked_achievements() -> Array:
	var unlocked = []
	for id in unlocked_achievements:
		unlocked.append(achievements[id])
	return unlocked

func get_achievement_points() -> int:
	var points = 0
	for id in unlocked_achievements:
		points += achievements[id].points
	return points

func get_completion_percentage() -> float:
	if achievements.is_empty():
		return 0.0
	return float(unlocked_achievements.size()) / float(achievements.size())
