extends Node3D

class_name SkillSystem

class Skill:
	var id: String
	var name: String
	var description: String
	var cooldown: float = 0.0
	var max_cooldown: float = 5.0
	var cost: int = 0
	var power: int = 10
	var range: float = 10.0

var skills: Dictionary = {}
var active_skills: Array[Skill] = []
var skill_cooldowns: Dictionary = {}

signal skill_learned(skill: Skill)
signal skill_used(skill: Skill)
signal skill_cooldown_updated(skill_id: String, remaining: float)

func _ready() -> void:
	_initialize_skills()

func _process(delta: float) -> void:
	_update_cooldowns(delta)

func _initialize_skills() -> void:
	var slash = Skill.new()
	slash.id = "slash"
	slash.name = "Slash"
	slash.description = "Basic melee attack"
	slash.max_cooldown = 2.0
	slash.power = 15

	var power_strike = Skill.new()
	power_strike.id = "power_strike"
	power_strike.name = "Power Strike"
	power_strike.description = "Powerful attack"
	power_strike.max_cooldown = 5.0
	power_strike.power = 30
	power_strike.cost = 20

	var call_for_help = Skill.new()
	call_for_help.id = "call_for_help"
	call_for_help.name = "Call for Help"
	call_for_help.description = "Call allies to aid"
	call_for_help.max_cooldown = 10.0
	call_for_help.range = 50.0

	skills["slash"] = slash
	skills["power_strike"] = power_strike
	skills["call_for_help"] = call_for_help

func learn_skill(skill_id: String) -> bool:
	if not skills.has(skill_id):
		return false

	if skill_id in [s.id for s in active_skills]:
		return false

	var skill = skills[skill_id]
	active_skills.append(skill)
	skill_cooldowns[skill_id] = 0.0

	skill_learned.emit(skill)
	return true

func use_skill(skill_id: String, user: Node3D, target: Node3D = null) -> bool:
	if not skills.has(skill_id):
		return false

	var skill = skills[skill_id]

	if skill_cooldowns.get(skill_id, 0.0) > 0.0:
		return false

	skill_cooldowns[skill_id] = skill.max_cooldown
	skill_used.emit(skill)

	return true

func _update_cooldowns(delta: float) -> void:
	for skill_id in skill_cooldowns.keys():
		if skill_cooldowns[skill_id] > 0.0:
			skill_cooldowns[skill_id] -= delta
			skill_cooldowns[skill_id] = max(0.0, skill_cooldowns[skill_id])
			skill_cooldown_updated.emit(skill_id, skill_cooldowns[skill_id])

func get_skill(skill_id: String) -> Skill:
	return skills.get(skill_id, null)

func get_active_skills() -> Array[Skill]:
	return active_skills.duplicate()

func get_skill_cooldown(skill_id: String) -> float:
	return skill_cooldowns.get(skill_id, 0.0)

func is_skill_ready(skill_id: String) -> bool:
	return get_skill_cooldown(skill_id) <= 0.0

func reset_cooldowns() -> void:
	for skill_id in skill_cooldowns.keys():
		skill_cooldowns[skill_id] = 0.0
