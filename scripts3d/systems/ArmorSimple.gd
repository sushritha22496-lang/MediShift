extends BaseSystemSimple

class_name ArmorSimple

class Armor:
	var id: String
	var name: String
	var slot: String
	var defense: float
	var magic_defense: float
	var weight: float
	var rarity: String
	func _init(p_id: String, p_name: String, p_slot: String, p_def: float, p_mdef: float, p_weight: float, p_rarity: String = "common") -> void:
		id = p_id
		name = p_name
		slot = p_slot
		defense = p_def
		magic_defense = p_mdef
		weight = p_weight
		rarity = p_rarity

var armors: Array[Armor] = []

signal armor_equipped(slot: String, armor: Armor)
signal armor_unequipped(slot: String)

func _ready() -> void:
	set_state("equipped", {})
	_initialize_armors()

func _initialize_armors() -> void:
	armors = [
		Armor.new("leather_helm", "Leather Helm", "head", 3.0, 1.0, 1.0, "common"),
		Armor.new("iron_helm", "Iron Helm", "head", 8.0, 2.0, 2.0, "uncommon"),
		Armor.new("steel_helm", "Steel Helm", "head", 12.0, 3.0, 2.5, "rare"),
		Armor.new("leather_chest", "Leather Chest", "chest", 5.0, 2.0, 2.0, "common"),
		Armor.new("iron_chest", "Iron Chest", "chest", 12.0, 4.0, 4.0, "uncommon"),
		Armor.new("steel_chest", "Steel Chest", "chest", 18.0, 6.0, 5.0, "rare"),
		Armor.new("leather_legs", "Leather Legs", "legs", 4.0, 1.5, 1.5, "common"),
		Armor.new("iron_legs", "Iron Legs", "legs", 10.0, 3.0, 3.0, "uncommon"),
		Armor.new("steel_legs", "Steel Legs", "legs", 15.0, 4.5, 3.5, "rare"),
		Armor.new("leather_boots", "Leather Boots", "feet", 2.0, 1.0, 0.8, "common"),
		Armor.new("iron_boots", "Iron Boots", "feet", 5.0, 1.5, 1.2, "uncommon"),
		Armor.new("steel_boots", "Steel Boots", "feet", 8.0, 2.0, 1.5, "rare")
	]

func equip_armor(armor_id: String) -> bool:
	for armor in armors:
		if armor.id == armor_id:
			var equipped = get_state("equipped", {})
			equipped[armor.slot] = armor
			set_state("equipped", equipped)
			armor_equipped.emit(armor.slot, armor)
			emit_event("armor_equipped", armor_id)
			return true
	return false

func unequip_armor(slot: String) -> void:
	var equipped = get_state("equipped", {})
	if slot in equipped:
		equipped.erase(slot)
		set_state("equipped", equipped)
		armor_unequipped.emit(slot)
		emit_event("armor_unequipped", slot)

func get_equipped_armor(slot: String) -> Armor:
	var equipped = get_state("equipped", {})
	return equipped.get(slot, null)

func get_armor(armor_id: String) -> Armor:
	for armor in armors:
		if armor.id == armor_id:
			return armor
	return null

func get_armor_by_slot(slot: String) -> Array[Armor]:
	return armors.filter(func(a): return a.slot == slot)

func get_total_defense() -> float:
	var equipped = get_state("equipped", {})
	var total = 0.0
	for armor in equipped.values():
		total += armor.defense
	return total

func get_total_magic_defense() -> float:
	var equipped = get_state("equipped", {})
	var total = 0.0
	for armor in equipped.values():
		total += armor.magic_defense
	return total

func get_armor_text() -> String:
	var equipped = get_state("equipped", {})
	var text = "Armor:\n"
	text += "Defense: %.0f | Magic Defense: %.0f\n" % [get_total_defense(), get_total_magic_defense()]
	for slot in ["head", "chest", "legs", "feet"]:
		if slot in equipped:
			text += "%s: %s\n" % [slot.capitalize(), equipped[slot].name]
	return text
