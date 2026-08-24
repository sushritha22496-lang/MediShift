extends BaseSystemSimple
class_name CharacterSimple

var level: int = 1
var exp: float = 0.0
var gold: float = 0.0
var stats: Dictionary = {
	"hp": 100.0, "max_hp": 100.0,
	"stamina": 100.0, "max_stamina": 100.0,
	"mana": 50.0, "max_mana": 50.0,
	"str": 10.0, "agi": 10.0, "int": 10.0, "vit": 10.0,
	"kills": 0, "deaths": 0, "playtime": 0.0
}

signal stat_changed(stat: String)
signal level_up(new_level: int)

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
	if exp >= level * 100:
		level += 1
		exp = 0
		level_up.emit(level)
		emit_event("level_up", level)

func add_gold(amount: float) -> void:
	gold += amount
	emit_event("gold_changed", gold)

func get_damage() -> float:
	return get_stat("str") * 1.5 + get_stat("int") * 0.5

func get_defense() -> float:
	return get_stat("vit") * 1.2

func to_text(prefix: String = "") -> String:
	return "%sLv %d | HP: %.0f/%.0f | Gold: %.0f | Exp: %.0f" % [
		prefix, level, get_stat("hp"), get_stat("max_hp"), gold, exp
	]
