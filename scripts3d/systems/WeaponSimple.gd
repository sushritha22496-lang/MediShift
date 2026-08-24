extends BaseSystemSimple

class_name WeaponSimple

class Weapon:
	var id: String
	var name: String
	var type: String
	var damage: float
	var attack_speed: float
	var weight: float
	var rarity: String
	var durability: float
	var max_durability: float
	var crit_chance: float
	var element: String
	var level_requirement: int
	func _init(p_id: String, p_name: String, p_type: String, p_damage: float, p_speed: float, p_weight: float, p_rarity: String = "common", p_crit: float = 0.05, p_element: String = "none", p_req: int = 1) -> void:
		id = p_id
		name = p_name
		type = p_type
		damage = p_damage
		attack_speed = p_speed
		weight = p_weight
		rarity = p_rarity
		crit_chance = p_crit
		element = p_element
		level_requirement = p_req
		max_durability = 100.0 + (p_damage * 2.0)
		durability = max_durability

var weapons: Array[Weapon] = []

signal weapon_equipped(weapon: Weapon)
signal weapon_unequipped
signal weapon_durability_changed(weapon_id: String, durability: float)
signal weapon_broken(weapon_id: String)
signal weapon_upgraded(weapon_id: String, level: int)
signal enchantment_added(weapon_id: String, effect: String)

func _ready() -> void:
	set_state("equipped", null)
	set_state("enchantments", {})
	set_state("weapon_upgrades", {})
	set_state("mastery", {})
	set_state("perks", {})
	set_state("element_intensity", {})
	_initialize_weapons()

func _initialize_weapons() -> void:
	weapons = [
		Weapon.new("wooden_sword", "Wooden Sword", "sword", 5.0, 1.2, 2.0, "common", 0.05, "none", 1),
		Weapon.new("iron_sword", "Iron Sword", "sword", 15.0, 1.0, 5.0, "uncommon", 0.08, "none", 3),
		Weapon.new("steel_sword", "Steel Sword", "sword", 25.0, 0.9, 6.0, "rare", 0.12, "none", 5),
		Weapon.new("wooden_bow", "Wooden Bow", "bow", 8.0, 1.5, 1.5, "common", 0.1, "none", 1),
		Weapon.new("longbow", "Longbow", "bow", 18.0, 1.3, 2.5, "uncommon", 0.15, "pierce", 4),
		Weapon.new("wooden_staff", "Wooden Staff", "staff", 6.0, 0.8, 3.0, "common", 0.0, "fire", 1),
		Weapon.new("mage_staff", "Mage Staff", "staff", 20.0, 0.9, 2.5, "rare", 0.05, "frost", 6),
		Weapon.new("dagger", "Dagger", "dagger", 12.0, 1.8, 1.0, "common", 0.2, "none", 2),
		Weapon.new("poisoned_dagger", "Poisoned Dagger", "dagger", 16.0, 1.7, 1.2, "rare", 0.18, "poison", 4),
		Weapon.new("great_sword", "Great Sword", "sword", 35.0, 0.7, 8.0, "epic", 0.15, "none", 8)
	]

func equip_weapon(weapon_id: String) -> bool:
	for weapon in weapons:
		if weapon.id == weapon_id:
			set_state("equipped", weapon)
			weapon_equipped.emit(weapon)
			emit_event("equipped", weapon_id)
			return true
	return false

func unequip_weapon() -> void:
	set_state("equipped", null)
	weapon_unequipped.emit()
	emit_event("unequipped", "weapon")

func get_equipped_weapon() -> Weapon:
	return get_state("equipped", null)

func get_weapon(weapon_id: String) -> Weapon:
	for weapon in weapons:
		if weapon.id == weapon_id:
			return weapon
	return null

func get_weapon_by_type(type: String) -> Array[Weapon]:
	return weapons.filter(func(w): return w.type == type)

func get_all_weapons() -> Array[Weapon]:
	return weapons

func get_weapon_damage() -> float:
	var weapon = get_equipped_weapon()
	return weapon.damage if weapon else 0.0

func get_weapon_text() -> String:
	var weapon = get_equipped_weapon()
	if not weapon:
		return "Weapon: None"
	var dur_pct = (weapon.durability / weapon.max_durability) * 100.0
	return "%s (Req: %d)\nDmg: %.0f | Spd: %.1f | Crit: %d%% | Dur: %.0f%%\nElement: %s" % [weapon.name, weapon.level_requirement, weapon.damage, weapon.attack_speed, int(weapon.crit_chance * 100), dur_pct, weapon.element.capitalize()]

func damage_weapon(weapon_id: String, damage: float) -> bool:
	var weapon = get_weapon(weapon_id)
	if weapon:
		weapon.durability = maxf(0.0, weapon.durability - damage)
		weapon_durability_changed.emit(weapon_id, weapon.durability)
		emit_event("weapon_damaged", weapon_id)
		if weapon.durability <= 0:
			weapon_broken.emit(weapon_id)
			emit_event("weapon_broken", weapon_id)
			return true
	return false

func repair_weapon(weapon_id: String, amount: float) -> void:
	var weapon = get_weapon(weapon_id)
	if weapon:
		weapon.durability = minf(weapon.max_durability, weapon.durability + amount)
		weapon_durability_changed.emit(weapon_id, weapon.durability)
		emit_event("weapon_repaired", weapon_id)

func get_effective_damage(weapon_id: String, str_bonus: float = 0.0) -> float:
	var weapon = get_weapon(weapon_id)
	if not weapon:
		return 0.0
	var dur_factor = weapon.durability / weapon.max_durability
	var base = weapon.damage + str_bonus
	return base * dur_factor * (1.0 + (randf_range(0.0, 0.15)))

func get_crit_multiplier(weapon_id: String) -> float:
	var weapon = get_weapon(weapon_id)
	if weapon and randf() < weapon.crit_chance:
		return 1.5 + (weapon.level_requirement * 0.1)
	return 1.0

func upgrade_weapon(weapon_id: String, materials: int = 1) -> bool:
	var weapon = get_weapon(weapon_id)
	if not weapon or materials <= 0:
		return false
	var upgrades = get_state("weapon_upgrades", {})
	var current = upgrades.get(weapon_id, 0)
	var new_level = current + 1
	if new_level > 10:
		return false
	weapon.damage *= 1.12
	weapon.max_durability *= 1.08
	weapon.durability = weapon.max_durability
	weapon.crit_chance += 0.02
	upgrades[weapon_id] = new_level
	set_state("weapon_upgrades", upgrades)
	weapon_upgraded.emit(weapon_id, new_level)
	emit_event("weapon_upgraded", {"weapon": weapon_id, "level": new_level})
	return true

func add_enchantment(weapon_id: String, enchant_id: String, power: float = 1.0) -> bool:
	var weapon = get_weapon(weapon_id)
	if not weapon:
		return false
	var enchants = get_state("enchantments", {})
	if weapon_id not in enchants:
		enchants[weapon_id] = []
	if enchants[weapon_id].size() >= 3:
		return false
	enchants[weapon_id].append({"id": enchant_id, "power": power, "active": true})
	set_state("enchantments", enchants)
	enchantment_added.emit(weapon_id, enchant_id)
	emit_event("enchantment_added", {"weapon": weapon_id, "enchant": enchant_id})
	return true

func add_weapon_perk(weapon_id: String, perk: String) -> void:
	var perks = get_state("perks", {})
	if weapon_id not in perks:
		perks[weapon_id] = []
	perks[weapon_id].append(perk)
	set_state("perks", perks)
	emit_event("perk_added", perk)

func track_weapon_mastery(weapon_id: String, exp: float = 1.0) -> void:
	var mastery = get_state("mastery", {})
	mastery[weapon_id] = mastery.get(weapon_id, 0.0) + exp
	set_state("mastery", mastery)

func get_weapon_mastery(weapon_id: String) -> float:
	var mastery = get_state("mastery", {})
	return mastery.get(weapon_id, 0.0)

func get_enchantments(weapon_id: String) -> Array:
	var enchants = get_state("enchantments", {})
	return enchants.get(weapon_id, [])

func increase_element_intensity(weapon_id: String, intensity: float = 0.1) -> void:
	var weapon = get_weapon(weapon_id)
	if not weapon or weapon.element == "none":
		return
	var elements = get_state("element_intensity", {})
	elements[weapon_id] = elements.get(weapon_id, 0.0) + intensity
	set_state("element_intensity", elements)
	emit_event("element_increased", weapon_id)
