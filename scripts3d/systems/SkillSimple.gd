extends Node

class_name SkillSimple

class Skill:
	var name: String
	var description: String
	var cooldown: float
	var damage: float
	var cooldown_remaining: float = 0.0

	func _init(p_name: String, p_desc: String, p_cooldown: float, p_damage: float) -> void:
		name = p_name
		description = p_desc
		cooldown = p_cooldown
		damage = p_damage

var learned_skills: Array[Skill] = []
var available_skills: Array[Skill] = []

signal skill_learned(skill: Skill)
signal skill_used(skill: Skill)

func _ready() -> void:
	_initialize_skills()

func _physics_process(delta: float) -> void:
	for skill in learned_skills:
		if skill.cooldown_remaining > 0:
			skill.cooldown_remaining -= delta

func _initialize_skills() -> void:
	var power_strike = Skill.new("Power Strike", "Deal 25 damage", 2.0, 25.0)
	var healing_meditation = Skill.new("Healing Meditation", "Restore health", 3.0, 0.0)
	var divine_call = Skill.new("Divine Call", "Summon allies", 5.0, 0.0)

	available_skills.append(power_strike)
	available_skills.append(healing_meditation)
	available_skills.append(divine_call)

	learn_skill(power_strike.name)

func learn_skill(skill_name: String) -> bool:
	for skill in available_skills:
		if skill.name == skill_name:
			if not skill in learned_skills:
				learned_skills.append(skill)
				skill_learned.emit(skill)
				return true
	return false

func use_skill(skill_name: String) -> bool:
	for skill in learned_skills:
		if skill.name == skill_name:
			if skill.cooldown_remaining <= 0:
				skill.cooldown_remaining = skill.cooldown
				skill_used.emit(skill)
				return true
	return false

func get_learned_skills() -> Array[Skill]:
	return learned_skills

func get_available_skills() -> Array[Skill]:
	return available_skills

func get_skill(skill_name: String) -> Skill:
	for skill in learned_skills:
		if skill.name == skill_name:
			return skill
	return null

func get_skills_text() -> String:
	var text = "Skills:\n"
	for skill in learned_skills:
		var cooldown_text = "Ready" if skill.cooldown_remaining <= 0 else "%.1fs" % skill.cooldown_remaining
		text += "%s [%s]\n" % [skill.name, cooldown_text]
	return text
