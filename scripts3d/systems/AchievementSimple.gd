extends TrackableSimple

class_name AchievementSimple

var all_achievements: Array[Track] = []
var achievement_categories: Dictionary = {}
var achievement_rewards: Dictionary = {}
var achievement_secrets: Array[String] = []

signal achievement_unlocked(track: Track)
signal milestone_reached(milestone: String)

func _ready() -> void:
	set_state("unlock_history", [])
	set_state("reward_history", [])
	set_state("category_progress", {})
	set_state("achievement_statistics", {})
	_initialize_achievements()

func _initialize_achievements() -> void:
	var first_steps = start("first_steps", "First Steps", 1, "achievement")
	first_steps.difficulty = 1
	achievement_rewards["first_steps"] = {"gold": 50, "exp": 25}
	achievement_categories["first_steps"] = "exploration"

	var meet_hanuman = start("meet_hanuman", "Meet Hanuman", 1, "achievement")
	meet_hanuman.difficulty = 1
	achievement_rewards["meet_hanuman"] = {"gold": 100, "exp": 50}
	achievement_categories["meet_hanuman"] = "story"

	var gatherer = start("gatherer", "Gatherer", 10, "achievement")
	gatherer.difficulty = 2
	achievement_rewards["gatherer"] = {"gold": 200, "exp": 100}
	achievement_categories["gatherer"] = "collection"

	var warrior = start("warrior", "Warrior", 5, "achievement")
	warrior.difficulty = 3
	achievement_rewards["warrior"] = {"gold": 500, "exp": 250}
	achievement_categories["warrior"] = "combat"

	var merchant = start("merchant", "Trader", 1, "achievement")
	merchant.difficulty = 1
	achievement_rewards["merchant"] = {"gold": 300, "exp": 150}
	achievement_categories["merchant"] = "economy"

	var explorer = start("explorer", "Explorer", 5, "achievement")
	explorer.difficulty = 2
	achievement_rewards["explorer"] = {"gold": 400, "exp": 200}
	achievement_categories["explorer"] = "exploration"

	var legend = start("legend", "Legend", 10, "achievement")
	legend.difficulty = 4
	achievement_rewards["legend"] = {"gold": 1000, "exp": 500}
	achievement_categories["legend"] = "legendary"
	achievement_secrets.append("legend")

	var rich = start("rich", "Rich", 1000, "achievement")
	rich.difficulty = 2
	achievement_rewards["rich"] = {"gold": 500, "exp": 300}
	achievement_categories["rich"] = "economy"

	all_achievements = active + completed

func _record_achievement_unlock(ach_id: String, category: String) -> void:
	var history = get_state("unlock_history", [])
	history.append({"achievement_id": ach_id, "category": category, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("unlock_history", history)

func _record_reward_grant(ach_id: String, reward: Dictionary) -> void:
	var history = get_state("reward_history", [])
	history.append({"achievement_id": ach_id, "reward": reward, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("reward_history", history)

func unlock_achievement(ach_id: String) -> bool:
	if complete(ach_id):
		var category = achievement_categories.get(ach_id, "general")
		_record_achievement_unlock(ach_id, category)
		var reward = achievement_rewards.get(ach_id, {})
		if reward:
			_record_reward_grant(ach_id, reward)
		return true
	return false

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

func update_achievement_statistics() -> void:
	var stats = get_state("achievement_statistics", {})
	var unlock_hist = get_state("unlock_history", [])
	var reward_hist = get_state("reward_history", [])
	stats["total_unlocked"] = completed.size()
	stats["total_active"] = active.size()
	stats["total_achievements"] = active.size() + completed.size()
	stats["completion_percent"] = (get_progress() * 100.0) if active.size() + completed.size() > 0 else 0.0
	stats["total_unlock_events"] = unlock_hist.size()
	stats["total_rewards_granted"] = reward_hist.size()
	var total_gold = 0.0
	var total_exp = 0.0
	for entry in reward_hist:
		var reward = entry.get("reward", {})
		total_gold += reward.get("gold", 0)
		total_exp += reward.get("exp", 0)
	stats["total_gold_rewarded"] = total_gold
	stats["total_exp_rewarded"] = total_exp
	stats["secret_achievements"] = achievement_secrets.size()
	set_state("achievement_statistics", stats)

func get_achievement_statistics() -> Dictionary:
	update_achievement_statistics()
	return get_state("achievement_statistics", {})
