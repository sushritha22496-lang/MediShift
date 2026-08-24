extends BaseSystemSimple

class_name StatisticsSimple

signal statistic_updated(stat_name: String, value: float)

func _ready() -> void:
	set_state("stats", {
		"playtime_hours": 0.0,
		"enemies_defeated": 0,
		"distance_traveled": 0.0,
		"quests_completed": 0,
		"items_collected": 0,
		"npcs_met": 0,
		"locations_discovered": 0,
		"deaths": 0,
		"gold_earned": 0.0,
		"gold_spent": 0.0,
		"hours_played_day": 0,
		"hours_played_night": 0,
		"battles_won": 0,
		"battles_lost": 0,
		"largest_combo": 0
	})

func increment_stat(stat_name: String, amount: float = 1.0) -> void:
	var stats = get_state("stats", {})
	if stat_name in stats:
		stats[stat_name] = stats[stat_name] + amount
		set_state("stats", stats)
		statistic_updated.emit(stat_name, stats[stat_name])
		emit_event("stat_updated", stat_name)

func set_stat(stat_name: String, value: float) -> void:
	var stats = get_state("stats", {})
	if stat_name in stats:
		stats[stat_name] = value
		set_state("stats", stats)
		statistic_updated.emit(stat_name, value)
		emit_event("stat_set", stat_name)

func get_stat(stat_name: String) -> float:
	var stats = get_state("stats", {})
	return stats.get(stat_name, 0.0)

func get_all_stats() -> Dictionary:
	return get_state("stats", {})

func get_win_rate() -> float:
	var wins = get_stat("battles_won")
	var losses = get_stat("battles_lost")
	var total = wins + losses
	return (wins / float(total)) * 100.0 if total > 0 else 0.0

func get_combat_stats_text() -> String:
	var text = "Combat Statistics\n"
	text += "Enemies Defeated: %.0f\n" % get_stat("enemies_defeated")
	text += "Battles Won: %.0f\n" % get_stat("battles_won")
	text += "Battles Lost: %.0f\n" % get_stat("battles_lost")
	text += "Win Rate: %.1f%%\n" % get_win_rate()
	text += "Largest Combo: %.0f\n" % get_stat("largest_combo")
	return text

func get_exploration_stats_text() -> String:
	var text = "Exploration Statistics\n"
	text += "Distance Traveled: %.0f\n" % get_stat("distance_traveled")
	text += "Locations Discovered: %.0f\n" % get_stat("locations_discovered")
	text += "NPCs Met: %.0f\n" % get_stat("npcs_met")
	text += "Items Collected: %.0f\n" % get_stat("items_collected")
	return text

func get_economy_stats_text() -> String:
	var text = "Economy Statistics\n"
	text += "Gold Earned: %.0f\n" % get_stat("gold_earned")
	text += "Gold Spent: %.0f\n" % get_stat("gold_spent")
	var balance = get_stat("gold_earned") - get_stat("gold_spent")
	text += "Net Balance: %.0f\n" % balance
	return text

func get_summary_text() -> String:
	var text = "=== GAME STATISTICS ===\n"
	text += "Playtime: %.1f hours\n" % get_stat("playtime_hours")
	text += "Quests Completed: %.0f\n" % get_stat("quests_completed")
	text += "Enemies Defeated: %.0f\n" % get_stat("enemies_defeated")
	text += "Deaths: %.0f\n" % get_stat("deaths")
	text += "Locations: %.0f | NPCs: %.0f\n" % [get_stat("locations_discovered"), get_stat("npcs_met")]
	return text
