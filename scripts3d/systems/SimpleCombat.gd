extends Node

class_name SimpleCombat

class Combatant:
	var name: String
	var health: float = 100.0
	var max_health: float = 100.0
	var attack: float = 10.0
	var defense: float = 5.0

	func damage(amt: float) -> float:
		var dmg = max(1, amt - defense)
		health -= dmg
		return dmg

	func alive() -> bool:
		return health > 0

signal combat_started(a: String, d: String)
signal damage_dealt(a: String, d: String, dmg: float)
signal combat_ended(winner: String)

func create_combatant(name: String, hp: float = 100, atk: float = 10, def: float = 5) -> Combatant:
	var c = Combatant.new()
	c.name = name
	c.health = hp
	c.max_health = hp
	c.attack = atk
	c.defense = def
	return c

func attack(attacker: Combatant, defender: Combatant) -> float:
	var dmg = attacker.attack * randf_range(0.8, 1.2)
	var actual = defender.damage(dmg)
	damage_dealt.emit(attacker.name, defender.name, actual)
	if not defender.alive():
		combat_ended.emit(attacker.name)
	return actual
