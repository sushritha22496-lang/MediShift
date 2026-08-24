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
signal armor_broken(armor_id: String)
signal set_bonus_activated(set_name: String)

func _ready() -> void:
	set_state("equipped", {})
	set_state("armor_durability", {})
	set_state("enchantments", {})
	set_state("armor_upgrades", {})
	set_state("armor_sets", {})
	set_state("equipment_history", [])
	set_state("durability_history", [])
	set_state("upgrade_history", [])
	set_state("enchantment_history", [])
	set_state("armor_statistics", {})
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

func _record_equipment_change(slot: String, armor_name: String, equipped: bool) -> void:
	var history = get_state("equipment_history", [])
	history.append({"slot": slot, "armor": armor_name, "equipped": equipped, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("equipment_history", history)

func _record_durability_change(armor_id: String, durability: float) -> void:
	var history = get_state("durability_history", [])
	history.append({"armor": armor_id, "durability": durability, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("durability_history", history)

func _record_upgrade(armor_id: String, new_level: int) -> void:
	var history = get_state("upgrade_history", [])
	history.append({"armor": armor_id, "level": new_level, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("upgrade_history", history)

func _record_enchantment(armor_id: String, enchant: String) -> void:
	var history = get_state("enchantment_history", [])
	history.append({"armor": armor_id, "enchantment": enchant, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("enchantment_history", history)

func equip_armor(armor_id: String) -> bool:
	for armor in armors:
		if armor.id == armor_id:
			var equipped = get_state("equipped", {})
			equipped[armor.slot] = armor
			set_state("equipped", equipped)
			_record_equipment_change(armor.slot, armor.name, true)
			armor_equipped.emit(armor.slot, armor)
			emit_event("armor_equipped", armor_id)
			return true
	return false

func unequip_armor(slot: String) -> void:
	var equipped = get_state("equipped", {})
	if slot in equipped:
		var armor_name = equipped[slot].name if equipped[slot] else "Unknown"
		_record_equipment_change(slot, armor_name, false)
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

func damage_armor(armor_id: String, damage: float) -> bool:
	var durability = get_state("armor_durability", {})
	if armor_id not in durability:
		durability[armor_id] = 100.0
	durability[armor_id] = maxf(0.0, durability[armor_id] - damage)
	set_state("armor_durability", durability)
	_record_durability_change(armor_id, durability[armor_id])
	if durability[armor_id] <= 0:
		armor_broken.emit(armor_id)
		emit_event("armor_broken", armor_id)
		return true
	return false

func repair_armor(armor_id: String, amount: float = 50.0) -> void:
	var durability = get_state("armor_durability", {})
	durability[armor_id] = minf(100.0, durability.get(armor_id, 100.0) + amount)
	set_state("armor_durability", durability)
	_record_durability_change(armor_id, durability[armor_id])
	emit_event("armor_repaired", armor_id)

func upgrade_armor(armor_id: String) -> bool:
	var armor = get_armor(armor_id)
	if not armor:
		return false
	var upgrades = get_state("armor_upgrades", {})
	var level = upgrades.get(armor_id, 0)
	if level >= 5:
		return false
	armor.defense *= 1.1
	armor.magic_defense *= 1.1
	upgrades[armor_id] = level + 1
	set_state("armor_upgrades", upgrades)
	_record_upgrade(armor_id, level + 1)
	emit_event("armor_upgraded", armor_id)
	return true

func add_enchantment(armor_id: String, enchant: String) -> void:
	var enchants = get_state("enchantments", {})
	if armor_id not in enchants:
		enchants[armor_id] = []
	enchants[armor_id].append(enchant)
	set_state("enchantments", enchants)
	_record_enchantment(armor_id, enchant)

func register_armor_set(set_name: String, armor_ids: Array) -> void:
	var sets = get_state("armor_sets", {})
	sets[set_name] = armor_ids
	set_state("armor_sets", sets)

func check_set_bonus(set_name: String) -> bool:
	var sets = get_state("armor_sets", {})
	var equipped = get_state("equipped", {})
	if set_name not in sets:
		return false
	var required = sets[set_name]
	var equipped_armors = equipped.values()
	var count = 0
	for req_id in required:
		for equip in equipped_armors:
			if equip.id == req_id:
				count += 1
				break
	if count == required.size():
		set_bonus_activated.emit(set_name)
		emit_event("set_bonus_active", set_name)
		return true
	return false

func get_armor_durability(armor_id: String) -> float:
	var durability = get_state("armor_durability", {})
	return durability.get(armor_id, 100.0)

func update_armor_statistics() -> void:
	var stats = get_state("armor_statistics", {})
	var equipment_hist = get_state("equipment_history", [])
	var durability_hist = get_state("durability_history", [])
	var upgrade_hist = get_state("upgrade_history", [])
	var enchant_hist = get_state("enchantment_history", [])
	var equipped = get_state("equipped", {})
	stats["total_equips"] = equipment_hist.size()
	stats["total_durability_changes"] = durability_hist.size()
	stats["total_upgrades"] = upgrade_hist.size()
	stats["total_enchantments"] = enchant_hist.size()
	stats["currently_equipped"] = equipped.size()
	stats["total_defense"] = get_total_defense()
	stats["total_magic_defense"] = get_total_magic_defense()
	set_state("armor_statistics", stats)

func get_armor_statistics() -> Dictionary:
	update_armor_statistics()
	return get_state("armor_statistics", {})
