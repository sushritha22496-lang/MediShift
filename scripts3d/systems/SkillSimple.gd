extends BaseSystemSimple

class_name SkillSimple

class Skill:
	var name: String
	var description: String
	var cooldown: float
	var damage: float
	func _init(p_name: String, p_desc: String, p_cooldown: float, p_damage: float) -> void:
		name = p_name
		description = p_desc
		cooldown = p_cooldown
		damage = p_damage

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
		Skill.new("Power Strike", "Deal 25 damage", 2.0, 25.0),
		Skill.new("Healing Meditation", "Restore health", 3.0, 0.0),
		Skill.new("Divine Call", "Summon allies", 5.0, 0.0)
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

func use_skill(skill_name: String) -> bool:
	var learned = get_state("learned", {})
	var cooldowns = get_state("cooldowns", {})
	if skill_name in learned:
		if cooldowns.get(skill_name, 0.0) <= 0:
			var skill = learned[skill_name]
			cooldowns[skill_name] = skill.cooldown
			skill_used.emit(skill)
			emit_event("skill_used", skill_name)
			return true
	return false

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
