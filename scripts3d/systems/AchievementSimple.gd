extends TrackableSimple

class_name AchievementSimple

var all_achievements: Array[Track] = []

signal achievement_unlocked(track: Track)

func _ready() -> void:
	_initialize_achievements()

func _initialize_achievements() -> void:
	all_achievements = [
		start("first_steps", "First Steps", 1, "achievement"),
		start("meet_hanuman", "Meet Hanuman", 1, "achievement"),
		start("gatherer", "Gatherer", 10, "achievement"),
		start("warrior", "Warrior", 5, "achievement"),
		start("merchant", "Trader", 1, "achievement"),
		start("explorer", "Explorer", 5, "achievement"),
		start("legend", "Legend", 10, "achievement"),
		start("rich", "Rich", 1000, "achievement")
	]

func unlock_achievement(ach_id: String) -> bool:
	return complete(ach_id)

func is_achievement_unlocked(ach_id: String) -> bool:
	for track in completed:
		if track.id == ach_id:
			return true
	return false

func get_achievement(ach_id: String) -> Track:
	for track in active:
		if track.id == ach_id:
			return track
	for track in completed:
		if track.id == ach_id:
			return track
	return null

func get_achievements_text() -> String:
	var text = "Achievements [%d/%d]:\n" % [completed.size(), active.size() + completed.size()]
	for track in active:
		text += "✗ %s\n" % track.title
	for track in completed:
		text += "✓ %s\n" % track.title
	return text

func get_progress() -> float:
	var total = active.size() + completed.size()
	return float(completed.size()) / float(total) if total > 0 else 0.0
