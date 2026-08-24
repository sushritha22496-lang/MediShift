extends BaseSystemSimple
class_name CharacterSimple

var level: int = 1
var exp: float = 0.0
var gold: float = 0.0
var skill_points: int = 0
var stats: Dictionary = {
	"hp": 100.0, "max_hp": 100.0,
	"stamina": 100.0, "max_stamina": 100.0,
	"mana": 50.0, "max_mana": 50.0,
	"str": 10.0, "agi": 10.0, "int": 10.0, "vit": 10.0,
	"kills": 0, "deaths": 0, "playtime": 0.0
}
var base_stats: Dictionary = {}
var stat_buffs: Dictionary = {"str": 0.0, "agi": 0.0, "int": 0.0, "vit": 0.0}
var proficiencies: Dictionary = {}

signal stat_changed(stat: String)
signal level_up(new_level: int)
signal skill_points_gained(amount: int)

func take_damage(amount: float) -> void:
	set_stat("hp", maxf(get_stat("hp") - amount, 0))
	if get_stat("hp") <= 0:
		emit_event("died", self)

func heal(amount: float) -> void:
	set_stat("hp", minf(get_stat("hp") + amount, get_stat("max_hp")))

func set_stat(key: String, value: float) -> void:
	if key in stats:
		stats[key] = value
		stat_changed.emit(key)
		if value <= 0 and key == "hp":
			emit_event("death", null)

func get_stat(key: String, default: float = 0.0) -> float:
	return stats.get(key, default)

func add_exp(amount: float) -> void:
	exp += amount
	var exp_requirement = get_exp_requirement(level)
	if exp >= exp_requirement:
		level_up_character()

func level_up_character() -> void:
	level += 1
	skill_points += 3
	exp = 0
	var str_gain = randi_range(1, 3)
	var agi_gain = randi_range(1, 3)
	var int_gain = randi_range(1, 2)
	var vit_gain = randi_range(2, 4)
	add_stat_permanent("str", str_gain)
	add_stat_permanent("agi", agi_gain)
	add_stat_permanent("int", int_gain)
	add_stat_permanent("vit", vit_gain)
	var max_hp_gain = vit_gain * 10.0 + (level * 5.0)
	set_stat("max_hp", get_stat("max_hp") + max_hp_gain)
	set_stat("hp", get_stat("max_hp"))
	level_up.emit(level)
	skill_points_gained.emit(3)
	emit_event("level_up", level)

func get_exp_requirement(lvl: int) -> float:
	return (lvl * lvl) * 50.0 + (lvl * 100.0)

func add_gold(amount: float) -> void:
	gold += amount
	emit_event("gold_changed", gold)

func add_stat_permanent(stat: String, amount: float) -> void:
	var current = get_stat(stat, 0.0)
	set_stat(stat, current + amount)

func apply_stat_buff(stat: String, amount: float) -> void:
	if stat in stat_buffs:
		stat_buffs[stat] += amount
		emit_event("buff_applied", stat)

func remove_stat_buff(stat: String, amount: float) -> void:
	if stat in stat_buffs:
		stat_buffs[stat] = maxf(0.0, stat_buffs[stat] - amount)
		emit_event("buff_removed", stat)

func get_effective_stat(stat: String) -> float:
	var base = get_stat(stat, 0.0)
	var buff = stat_buffs.get(stat, 0.0)
	return base + buff

func get_damage() -> float:
	var str_bonus = get_effective_stat("str")
	var int_bonus = get_effective_stat("int")
	var level_factor = 1.0 + (level * 0.1)
	return (str_bonus * 1.5 + int_bonus * 0.5) * level_factor

func get_defense() -> float:
	var vit_bonus = get_effective_stat("vit")
	var level_factor = 1.0 + (level * 0.05)
	return (vit_bonus * 1.2) * level_factor

func add_proficiency(skill: String, amount: float = 1.0) -> void:
	if skill not in proficiencies:
		proficiencies[skill] = 0.0
	proficiencies[skill] += amount
	emit_event("proficiency_increased", skill)

func get_proficiency(skill: String) -> float:
	return proficiencies.get(skill, 0.0)

func allocate_skill_point(stat: String) -> bool:
	if skill_points > 0 and stat in stats:
		add_stat_permanent(stat, 1)
		skill_points -= 1
		emit_event("skill_point_allocated", stat)
		return true
	return false

func to_text(prefix: String = "") -> String:
	var exp_req = get_exp_requirement(level)
	var exp_pct = (exp / exp_req) * 100.0
	return "%sLv %d | HP: %.0f/%.0f | SP: %d | Gold: %.0f | Exp: %.0f/%.0f (%.0f%%)" % [
		prefix, level, get_stat("hp"), get_stat("max_hp"), skill_points, gold, exp, exp_req, exp_pct
	]
