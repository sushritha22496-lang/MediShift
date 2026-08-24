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
