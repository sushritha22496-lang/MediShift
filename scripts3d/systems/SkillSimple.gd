extends BaseSystemSimple

class_name SkillSimple

class Skill:
	var name: String
	var description: String
	var cooldown: float
	var damage: float
	var mana_cost: float
	var level: int
	var max_level: int
	var prerequisite: String
	var requires_level: int
	var passive_bonus: Dictionary
	func _init(p_name: String, p_desc: String, p_cooldown: float, p_damage: float, p_mana: float = 0.0, p_req_level: int = 1, p_prereq: String = "") -> void:
		name = p_name
		description = p_desc
		cooldown = p_cooldown
		damage = p_damage
		mana_cost = p_mana
		level = 0
		max_level = 5
		requires_level = p_req_level
		prerequisite = p_prereq
		passive_bonus = {}

var available_skills: Array[Skill] = []

signal skill_learned(skill: Skill)
signal skill_used(skill: Skill)
signal skill_leveled(skill: String, level: int)
signal skill_tree_unlocked(skill: String)

func _ready() -> void:
	set_state("learned", {})
	set_state("cooldowns", {})
	set_state("skill_stats", {})
	set_state("skill_variations", {})
	set_state("usage_count", {})
	set_state("tree_unlocked", {})
	set_state("skill_learning_history", [])
	set_state("skill_upgrade_history", [])
	set_state("skill_usage_history", [])
	set_state("skill_statistics", {})
	_initialize_skills()

func _physics_process(delta: float) -> void:
	var cooldowns = get_state("cooldowns", {})
	for skill_name in cooldowns:
		if cooldowns[skill_name] > 0:
			cooldowns[skill_name] -= delta

func _initialize_skills() -> void:
	available_skills = [
		Skill.new("Power Strike", "Deal 25 damage", 2.0, 25.0, 0.0, 1, ""),
		Skill.new("Slash Combo", "Chain 3 strikes", 3.0, 40.0, 0.0, 5, "Power Strike"),
		Skill.new("Healing Meditation", "Restore health", 3.0, 0.0, 20.0, 3, ""),
		Skill.new("Divine Protection", "Shield allies", 5.0, 0.0, 30.0, 8, "Healing Meditation"),
		Skill.new("Divine Call", "Summon allies", 5.0, 0.0, 50.0, 10, "Divine Protection")
	]
	learn_skill("Power Strike")

func _record_skill_learned(skill_name: String) -> void:
	var history = get_state("skill_learning_history", [])
	history.append({"skill": skill_name, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("skill_learning_history", history)

func _record_skill_upgrade(skill_name: String, new_level: int) -> void:
	var history = get_state("skill_upgrade_history", [])
	history.append({"skill": skill_name, "level": new_level, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("skill_upgrade_history", history)

func _record_skill_usage(skill_name: String) -> void:
	var history = get_state("skill_usage_history", [])
	history.append({"skill": skill_name, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("skill_usage_history", history)

func learn_skill(skill_name: String) -> bool:
	for skill in available_skills:
		if skill.name == skill_name:
			var learned = get_state("learned", {})
			if not skill_name in learned:
				learned[skill_name] = skill
				set_state("learned", learned)
				_record_skill_learned(skill_name)
				skill_learned.emit(skill)
				get_state("cooldowns", {})[skill_name] = 0.0
				return true
	return false

func use_skill(skill_name: String, current_mana: float = 100.0) -> bool:
	var learned = get_state("learned", {})
	var cooldowns = get_state("cooldowns", {})
	if skill_name in learned:
		var skill = learned[skill_name]
		if cooldowns.get(skill_name, 0.0) <= 0 and current_mana >= skill.mana_cost:
			cooldowns[skill_name] = skill.cooldown
			_record_skill_usage(skill_name)
			track_skill_usage(skill_name)
			skill_used.emit(skill)
			emit_event("skill_used", skill_name)
			return true
	return false

func upgrade_skill(skill_name: String) -> bool:
	var learned = get_state("learned", {})
	if skill_name in learned:
		var skill = learned[skill_name]
		if skill.level < skill.max_level:
			skill.level += 1
			skill.damage *= 1.1
			skill.cooldown *= 0.95
			skill.mana_cost *= 1.05
			_record_skill_upgrade(skill_name, skill.level)
			skill_leveled.emit(skill_name, skill.level)
			emit_event("skill_upgraded", {"name": skill_name, "level": skill.level})
			return true
	return false

func can_learn_skill(skill_name: String, player_level: int) -> bool:
	for skill in available_skills:
		if skill.name == skill_name:
			if player_level < skill.requires_level:
				return false
			if skill.prerequisite != "" and not has_skill(skill.prerequisite):
				return false
			return true
	return false

func has_skill(skill_name: String) -> bool:
	var learned = get_state("learned", {})
	return skill_name in learned

func get_skill_proficiency(skill_name: String) -> int:
	var learned = get_state("learned", {})
	if skill_name in learned:
		return learned[skill_name].level
	return 0

func get_effective_damage(skill_name: String, int_bonus: float = 0.0) -> float:
	var learned = get_state("learned", {})
	if skill_name in learned:
		var skill = learned[skill_name]
		return skill.damage * (1.0 + (skill.level * 0.15)) + int_bonus
	return 0.0

func get_learned_skills() -> Array:
	var learned = get_state("learned", {})
	return learned.values()

func get_skill(skill_name: String) -> Skill:
	var learned = get_state("learned", {})
	return learned.get(skill_name, null)

func get_skills_text() -> String:
	var learned = get_state("learned", {})
	var cooldowns = get_state("cooldowns", {})
	var text = "Skills:\n"
	for skill_name in learned:
		var cooldown_text = "Ready" if cooldowns.get(skill_name, 0.0) <= 0 else "%.1fs" % cooldowns.get(skill_name, 0.0)
		text += "%s [%s]\n" % [skill_name, cooldown_text]
	return text

func add_skill_variation(skill_name: String, variation: String) -> bool:
	var learned = get_state("learned", {})
	if skill_name not in learned:
		return false
	var variations = get_state("skill_variations", {})
	if skill_name not in variations:
		variations[skill_name] = []
	variations[skill_name].append(variation)
	set_state("skill_variations", variations)
	emit_event("variation_added", skill_name)
	return true

func get_skill_variations(skill_name: String) -> Array:
	var variations = get_state("skill_variations", {})
	return variations.get(skill_name, [])

func track_skill_usage(skill_name: String) -> void:
	var usage = get_state("usage_count", {})
	usage[skill_name] = usage.get(skill_name, 0) + 1
	set_state("usage_count", usage)

func get_skill_usage_count(skill_name: String) -> int:
	var usage = get_state("usage_count", {})
	return usage.get(skill_name, 0)

func unlock_skill_tree(tree_name: String) -> void:
	var unlocked = get_state("tree_unlocked", {})
	unlocked[tree_name] = true
	set_state("tree_unlocked", unlocked)
	skill_tree_unlocked.emit(tree_name)
	emit_event("tree_unlocked", tree_name)

func is_tree_unlocked(tree_name: String) -> bool:
	var unlocked = get_state("tree_unlocked", {})
	return unlocked.get(tree_name, false)

func get_skill_stats(skill_name: String) -> Dictionary:
	var stats = get_state("skill_stats", {})
	return stats.get(skill_name, {"casts": 0, "hits": 0, "crits": 0, "effectiveness": 0.0})

func update_skill_statistics() -> void:
	var stats = get_state("skill_statistics", {})
	var learn_hist = get_state("skill_learning_history", [])
	var upgrade_hist = get_state("skill_upgrade_history", [])
	var usage_hist = get_state("skill_usage_history", [])
	var learned = get_state("learned", {})
	stats["total_skills_learned"] = learn_hist.size()
	stats["total_upgrades"] = upgrade_hist.size()
	stats["total_usages"] = usage_hist.size()
	stats["currently_learned"] = learned.size()
	var usage = get_state("usage_count", {})
	stats["most_used_skill"] = ""
	var max_uses = 0
	for skill_name in usage:
		if usage[skill_name] > max_uses:
			max_uses = usage[skill_name]
			stats["most_used_skill"] = skill_name
	set_state("skill_statistics", stats)

func get_skill_statistics() -> Dictionary:
	update_skill_statistics()
	return get_state("skill_statistics", {})
