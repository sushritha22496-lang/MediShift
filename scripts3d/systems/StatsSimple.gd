extends Node

class_name StatsSimple

@export var base_strength: float = 10.0
@export var base_agility: float = 10.0
@export var base_intelligence: float = 10.0
@export var base_vitality: float = 10.0

var strength: float
var agility: float
var intelligence: float
var vitality: float
var total_kills: int = 0
var total_deaths: int = 0
var playtime: float = 0.0
var distance_traveled: float = 0.0

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
			strength += amount
		"agility":
			agility += amount
		"intelligence":
			intelligence += amount
		"vitality":
			vitality += amount
	stat_increased.emit(stat_name, get_stat(stat_name))

func add_kill() -> void:
	total_kills += 1

func add_death() -> void:
	total_deaths += 1

func add_distance(distance: float) -> void:
	distance_traveled += distance

func get_stat(stat_name: String) -> float:
	match stat_name:
		"strength":
			return strength
		"agility":
			return agility
		"intelligence":
			return intelligence
		"vitality":
			return vitality
	return 0.0

func get_total_damage() -> float:
	return strength * 1.5 + intelligence * 0.5

func get_total_defense() -> float:
	return vitality * 1.2

func get_total_evasion() -> float:
	return agility * 0.8

func get_total_magic() -> float:
	return intelligence * 2.0

func get_playtime_text() -> String:
	var hours = int(playtime / 3600)
	var minutes = int((playtime % 3600) / 60)
	return "%02d:%02d" % [hours, minutes]

func get_stats_text() -> String:
	var text = "Character Stats:\n"
	text += "STR: %.0f | AGI: %.0f\n" % [strength, agility]
	text += "INT: %.0f | VIT: %.0f\n" % [intelligence, vitality]
	text += "Kills: %d | Deaths: %d\n" % [total_kills, total_deaths]
	text += "Distance: %.0fm\n" % distance_traveled
	text += "Playtime: %s\n" % get_playtime_text()
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
