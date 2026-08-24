extends BaseSystemSimple

class_name CompletionTrackingSimple

signal category_completed(category: String, percentage: float)
signal completion_updated(percentage: float)

var completion_categories: Dictionary = {
	"quests": {"total": 20, "completed": 0},
	"bosses": {"total": 15, "completed": 0},
	"treasures": {"total": 50, "completed": 0},
	"collectibles": {"total": 100, "completed": 0},
	"locations": {"total": 30, "completed": 0},
	"skills": {"total": 25, "completed": 0},
	"achievements": {"total": 40, "completed": 0},
	"sidequests": {"total": 50, "completed": 0}
}

func _ready() -> void:
	set_state("category_percentages", {})
	set_state("completion_history", [])
	set_state("category_unlocks", {})
	set_state("completion_rewards", {})
	set_state("speedrun_times", {})
	set_state("difficulty_scaled_progress", {})
	set_state("completion_statistics", {})
	set_state("completion_rate_by_time", [])

func complete_item(category: String) -> void:
	if category in completion_categories:
		completion_categories[category]["completed"] += 1
		var completed = completion_categories[category]["completed"]
		var total = completion_categories[category]["total"]
		var percentage = (float(completed) / float(total)) * 100.0
		
		var percentages = get_state("category_percentages", {})
		percentages[category] = percentage
		set_state("category_percentages", percentages)
		
		if percentage == 100.0:
			category_completed.emit(category, percentage)
			emit_event("category_completed", category)
		
		completion_updated.emit(get_total_completion())
		emit_event("completion_updated", category)

func get_category_completion(category: String) -> float:
	var percentages = get_state("category_percentages", {})
	return percentages.get(category, 0.0)

func get_total_completion() -> float:
	var total_items = 0
	var completed_items = 0
	for cat in completion_categories.values():
		total_items += cat["total"]
		completed_items += cat["completed"]
	return (float(completed_items) / float(total_items)) * 100.0 if total_items > 0 else 0.0

func get_completion_by_category() -> Dictionary:
	var result = {}
	for category in completion_categories.keys():
		var data = completion_categories[category]
		result[category] = (float(data["completed"]) / float(data["total"])) * 100.0
	return result

func get_completed_categories() -> Array:
	var completed = []
	for category in completion_categories.keys():
		if get_category_completion(category) == 100.0:
			completed.append(category)
	return completed

func get_completion_text() -> String:
	var text = "Completion: %.0f%%\n\n" % get_total_completion()
	for category in completion_categories.keys():
		var percent = get_category_completion(category)
		var bar_length = int(percent / 10.0)
		var bar = "█".repeat(bar_length) + "░".repeat(10 - bar_length)
		text += "%s: %s %.0f%%\n" % [category.capitalize(), bar, percent]
	return text

func get_completion_summary() -> String:
	var text = "=== COMPLETION SUMMARY ===\n"
	text += "Overall: %.0f%%\n\n" % get_total_completion()
	for category in completion_categories.keys():
		var data = completion_categories[category]
		text += "%s: %d/%d\n" % [category.capitalize(), data["completed"], data["total"]]
	var completed = get_completed_categories()
	if completed.size() > 0:
		text += "\nCompleted: %s\n" % ", ".join(completed)
	return text

func record_completion_history(category: String, item_count: int) -> void:
	var history = get_state("completion_history", [])
	history.append({"category": category, "items": item_count, "time": Time.get_ticks_msec()})
	if history.size() > 100:
		history.pop_front()
	set_state("completion_history", history)

func unlock_category(category: String) -> void:
	var unlocks = get_state("category_unlocks", {})
	unlocks[category] = {"unlocked": true, "time": Time.get_ticks_msec()}
	set_state("category_unlocks", unlocks)
	emit_event("category_unlocked", category)

func record_completion_reward(category: String, reward: Dictionary) -> void:
	var rewards = get_state("completion_rewards", {})
	if category not in rewards:
		rewards[category] = []
	rewards[category].append(reward)
	set_state("completion_rewards", rewards)
	emit_event("reward_earned", category)

func record_speedrun_time(category: String, time_ms: int) -> void:
	var speedruns = get_state("speedrun_times", {})
	if category not in speedruns:
		speedruns[category] = time_ms
	else:
		speedruns[category] = mini(speedruns[category], time_ms)
	set_state("speedrun_times", speedruns)
	emit_event("speedrun_recorded", category)

func get_speedrun_time(category: String) -> int:
	var speedruns = get_state("speedrun_times", {})
	return speedruns.get(category, -1)

func set_difficulty_scaled_progress(category: String, difficulty: int, progress: float) -> void:
	var scaled = get_state("difficulty_scaled_progress", {})
	var key = "%s_d%d" % [category, difficulty]
	scaled[key] = progress
	set_state("difficulty_scaled_progress", scaled)

func update_completion_statistics() -> void:
	var stats = get_state("completion_statistics", {})
	stats["total_completion"] = get_total_completion()
	stats["completed_categories"] = get_completed_categories().size()
	stats["history_entries"] = get_state("completion_history", []).size()
	set_state("completion_statistics", stats)

func record_completion_rate(completion_rate: float) -> void:
	var rates = get_state("completion_rate_by_time", [])
	rates.append({"rate": completion_rate, "time": Time.get_ticks_msec()})
	if rates.size() > 50:
		rates.pop_front()
	set_state("completion_rate_by_time", rates)

func get_completion_history() -> Array:
	return get_state("completion_history", [])

func get_completion_statistics() -> Dictionary:
	update_completion_statistics()
	return get_state("completion_statistics", {})
