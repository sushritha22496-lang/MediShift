extends Node

class_name StatsSimple

@export var base_strength: float = 10.0
@export var base_agility: float = 10.0
@export var base_intelligence: float = 10.0
@export var base_vitality: float = 10.0
@export var max_stat_value: float = 99.0
@export var level: int = 1

var strength: float
var agility: float
var intelligence: float
var vitality: float
var strength_bonus: float = 0.0
var agility_bonus: float = 0.0
var intelligence_bonus: float = 0.0
var vitality_bonus: float = 0.0
var total_kills: int = 0
var total_deaths: int = 0
var playtime: float = 0.0
var distance_traveled: float = 0.0
var critical_hits: int = 0
var blocks: int = 0
var kills_by_weapon: Dictionary = {}
var combat_stats: Dictionary = {"damage_dealt": 0.0, "damage_taken": 0.0, "times_hit": 0, "attacks_landed": 0}
var achievements_bonus: Dictionary = {}

signal stat_increased(stat_name: String, new_value: float)
signal stat_increased_levelup

func _ready() -> void:
	strength = base_strength
	agility = base_agility
	intelligence = base_intelligence
	vitality = base_vitality

func _process(delta: float) -> void:
	playtime += delta

func increase_stat(stat_name: String, amount: float = 1.0) -> void:
	match stat_name:
		"strength":
			strength = clamp(strength + amount, 0.0, max_stat_value)
		"agility":
			agility = clamp(agility + amount, 0.0, max_stat_value)
		"intelligence":
			intelligence = clamp(intelligence + amount, 0.0, max_stat_value)
		"vitality":
			vitality = clamp(vitality + amount, 0.0, max_stat_value)
	stat_increased.emit(stat_name, get_stat(stat_name))

func apply_stat_bonus(stat_name: String, amount: float) -> void:
	match stat_name:
		"strength":
			strength_bonus += amount
		"agility":
			agility_bonus += amount
		"intelligence":
			intelligence_bonus += amount
		"vitality":
			vitality_bonus += amount

func record_damage_dealt(damage: float, weapon_type: String = "unarmed") -> void:
	combat_stats["damage_dealt"] += damage
	kills_by_weapon[weapon_type] = kills_by_weapon.get(weapon_type, 0) + 1
	combat_stats["attacks_landed"] += 1

func record_damage_taken(damage: float) -> void:
	combat_stats["damage_taken"] += damage
	combat_stats["times_hit"] += 1

func record_critical_hit() -> void:
	critical_hits += 1

func record_block() -> void:
	blocks += 1

func set_level(new_level: int) -> void:
	level = new_level
	var stat_growth = (new_level - 1) * 0.5
	strength = base_strength + stat_growth
	agility = base_agility + stat_growth
	intelligence = base_intelligence + stat_growth
	vitality = base_vitality + stat_growth

func add_kill() -> void:
	total_kills += 1

func add_death() -> void:
	total_deaths += 1

func add_distance(distance: float) -> void:
	distance_traveled += distance

func get_stat(stat_name: String) -> float:
	match stat_name:
		"strength":
			return strength + strength_bonus
		"agility":
			return agility + agility_bonus
		"intelligence":
			return intelligence + intelligence_bonus
		"vitality":
			return vitality + vitality_bonus
	return 0.0

func get_total_damage() -> float:
	return (strength + strength_bonus) * 1.5 + (intelligence + intelligence_bonus) * 0.5

func get_total_defense() -> float:
	return (vitality + vitality_bonus) * 1.2

func get_total_evasion() -> float:
	return (agility + agility_bonus) * 0.8

func get_total_magic() -> float:
	return (intelligence + intelligence_bonus) * 2.0

func get_critical_hit_rate() -> float:
	var base_rate = (agility + agility_bonus) * 0.002
	return clamp(base_rate, 0.0, 0.5)

func get_block_rate() -> float:
	var base_rate = (agility + agility_bonus) * 0.001
	return clamp(base_rate, 0.0, 0.3)

func get_playtime_text() -> String:
	var hours = int(playtime / 3600)
	var minutes = int((playtime % 3600) / 60)
	return "%02d:%02d" % [hours, minutes]

func get_stats_text() -> String:
	var text = "Character [Lvl %d]\n" % level
	text += "STR: %.0f | AGI: %.0f | INT: %.0f | VIT: %.0f\n" % [get_stat("strength"), get_stat("agility"), get_stat("intelligence"), get_stat("vitality")]
	text += "DMG: %.0f | DEF: %.0f | CRIT: %.0f%%\n" % [get_total_damage(), get_total_defense(), get_critical_hit_rate() * 100.0]
	text += "K/D: %d/%d | Blocks: %d\n" % [total_kills, total_deaths, blocks]
	text += "Distance: %.0fm | Playtime: %s\n" % [distance_traveled, get_playtime_text()]
	return text

func reset_to_base() -> void:
	strength = base_strength
	agility = base_agility
	intelligence = base_intelligence
	vitality = base_vitality
	total_kills = 0
	total_deaths = 0
	playtime = 0.0
	distance_traveled = 0.0
