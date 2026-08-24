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

func _ready() -> void:
	set_state("learned", {})
	set_state("cooldowns", {})
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

func learn_skill(skill_name: String) -> bool:
	for skill in available_skills:
		if skill.name == skill_name:
			var learned = get_state("learned", {})
			if not skill_name in learned:
				learned[skill_name] = skill
				set_state("learned", learned)
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
