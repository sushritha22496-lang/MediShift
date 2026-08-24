extends BaseSystemSimple

class_name EquipmentSimple

class Equipment:
	var id: String
	var name: String
	var slot: String
	var damage: float = 0.0
	var defense: float = 0.0
	var durability: float = 100.0
	var max_durability: float = 100.0
	var rarity: String = "common"
	var level_requirement: int = 1
	var weight: float = 1.0
	var enchantment_slots: int = 0
	var stat_modifiers: Dictionary = {}
	var set_name: String = ""
	var breakage_chance: float = 0.0
	var is_cursed: bool = false
	var blessing: String = ""
	func _init(p_id: String, p_name: String, p_slot: String, p_rarity: String = "common") -> void:
		id = p_id
		name = p_name
		slot = p_slot
		rarity = p_rarity
		_initialize_rarity_stats(p_rarity)

	func _initialize_rarity_stats(p_rarity: String) -> void:
		match p_rarity:
			"common":
				damage = 5.0
				defense = 2.0
				enchantment_slots = 0
			"uncommon":
				damage = 8.0
				defense = 4.0
				enchantment_slots = 1
			"rare":
				damage = 12.0
				defense = 7.0
				enchantment_slots = 2
			"epic":
				damage = 18.0
				defense = 11.0
				enchantment_slots = 3
			"legendary":
				damage = 25.0
				defense = 16.0
				enchantment_slots = 4

var available_slots: Array[String] = ["head", "body", "hands", "legs", "feet", "weapon", "shield"]

signal equipment_equipped(equipment: Equipment)
signal equipment_unequipped(slot: String)
signal durability_changed(equipment: Equipment)

func _ready() -> void:
	var equipped = {}
	for slot in available_slots:
		equipped[slot] = null
	set_state("equipped", equipped)
	set_state("equipment_sets", {})
	set_state("total_weight", 0.0)
	set_state("carry_capacity", 50.0)
	set_state("equipment_enchantments", {})

func equip(equipment: Equipment, player_level: int = 1) -> bool:
	var equipped = get_state("equipped", {})
	if not equipment.slot in equipped:
		return false
	if player_level < equipment.level_requirement:
		return false
	var current_weight = get_state("total_weight", 0.0)
	var capacity = get_state("carry_capacity", 50.0)
	if current_weight + equipment.weight > capacity:
		return false
	var old_equipment = equipped[equipment.slot]
	if old_equipment:
		current_weight -= old_equipment.weight
	equipped[equipment.slot] = equipment
	set_state("total_weight", current_weight + equipment.weight)
	equipment_equipped.emit(equipment)
	if old_equipment:
		equipment_unequipped.emit(equipment.slot)
	emit_event("equipped", equipment.name)
	return true

func unequip(slot: String) -> bool:
	var equipped = get_state("equipped", {})
	if slot in equipped and equipped[slot] != null:
		var equipment = equipped[slot]
		var current_weight = get_state("total_weight", 0.0)
		set_state("total_weight", current_weight - equipment.weight)
		equipped[slot] = null
		equipment_unequipped.emit(slot)
		emit_event("unequipped", slot)
		return true
	return false

func get_equipped(slot: String) -> Equipment:
	var equipped = get_state("equipped", {})
	return equipped.get(slot, null)

func get_total_damage() -> float:
	var equipped = get_state("equipped", {})
	var total = 0.0
	for slot in equipped:
		if equipped[slot] != null:
			var eq = equipped[slot]
			var damage = eq.damage
			if "damage" in eq.stat_modifiers:
				damage *= 1.0 + eq.stat_modifiers["damage"]
			total += damage
	return total

func get_total_defense() -> float:
	var equipped = get_state("equipped", {})
	var total = 0.0
	for slot in equipped:
		if equipped[slot] != null:
			var eq = equipped[slot]
			var defense = eq.defense
			if "defense" in eq.stat_modifiers:
				defense *= 1.0 + eq.stat_modifiers["defense"]
			total += defense
	return total

func get_stat_modifier(stat: String) -> float:
	var equipped = get_state("equipped", {})
	var total_mod = 0.0
	for slot in equipped:
		if equipped[slot] != null and stat in equipped[slot].stat_modifiers:
			total_mod += equipped[slot].stat_modifiers[stat]
	return total_mod

func reduce_durability(slot: String, amount: float = 1.0) -> void:
	var equipped = get_state("equipped", {})
	if slot in equipped and equipped[slot] != null:
		var eq = equipped[slot]
		if randf() < eq.breakage_chance:
			unequip(slot)
			emit_event("equipment_broke", eq.id)
			return
		eq.durability -= amount
		durability_changed.emit(eq)
		if eq.durability <= 0:
			unequip(slot)

func repair(slot: String, amount: float = 50.0) -> void:
	var equipped = get_state("equipped", {})
	if slot in equipped and equipped[slot] != null:
		equipped[slot].durability = minf(equipped[slot].durability + amount, equipped[slot].max_durability)
		durability_changed.emit(equipped[slot])

func get_carrying_capacity_percent() -> float:
	var weight = get_state("total_weight", 0.0)
	var capacity = get_state("carry_capacity", 50.0)
	return (weight / capacity) * 100.0

func add_set_bonus(set_name: String, bonus_dict: Dictionary) -> void:
	var sets = get_state("equipment_sets", {})
	sets[set_name] = bonus_dict
	set_state("equipment_sets", sets)

func get_set_bonus(set_name: String) -> Dictionary:
	var sets = get_state("equipment_sets", {})
	return sets.get(set_name, {})

func get_active_set_bonuses() -> Dictionary:
	var equipped = get_state("equipped", {})
	var sets = get_state("equipment_sets", {})
	var active_sets = {}
	for slot in equipped:
		if equipped[slot] != null and equipped[slot].set_name != "":
			active_sets[equipped[slot].set_name] = true
	var bonuses = {}
	for set_name in active_sets:
		if set_name in sets:
			bonuses[set_name] = sets[set_name]
	return bonuses

func add_enchantment_to_slot(slot: String, enchantment_id: String) -> bool:
	var equipped = get_state("equipped", {})
	if slot not in equipped or equipped[slot] == null:
		return false
	var eq = equipped[slot]
	var enchs = get_state("equipment_enchantments", {})
	if slot not in enchs:
		enchs[slot] = []
	if enchs[slot].size() < eq.enchantment_slots:
		enchs[slot].append(enchantment_id)
		set_state("equipment_enchantments", enchs)
		emit_event("enchantment_added", {"slot": slot, "enchantment": enchantment_id})
		return true
	return false

func get_equipment_text() -> String:
	var equipped = get_state("equipped", {})
	var weight_pct = get_carrying_capacity_percent()
	var text = "Equipment [%.0f%% Load]:\n" % weight_pct
	for slot in available_slots:
		if equipped[slot] != null:
			var eq = equipped[slot]
			text += "%s: %s [%s] (%.0f%%)\n" % [slot, eq.name, eq.rarity, eq.durability]
		else:
			text += "%s: Empty\n" % slot
	return text
