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
	set_state("equipment_history", [])
	set_state("durability_tracking", [])
	set_state("repair_history", [])
	set_state("weight_management_history", [])
	set_state("equipment_statistics", {})

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
	var new_weight = current_weight + equipment.weight
	set_state("total_weight", new_weight)
	_record_equipment_change(equipment.slot, equipment.name, true)
	_record_weight_change(new_weight)
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
		var new_weight = current_weight - equipment.weight
		set_state("total_weight", new_weight)
		_record_equipment_change(slot, equipment.name, false)
		_record_weight_change(new_weight)
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
		_record_durability_change(eq.name, eq.durability)
		durability_changed.emit(eq)
		if eq.durability <= 0:
			unequip(slot)

func repair(slot: String, amount: float = 50.0) -> void:
	var equipped = get_state("equipped", {})
	if slot in equipped and equipped[slot] != null:
		var new_durability = minf(equipped[slot].durability + amount, equipped[slot].max_durability)
		equipped[slot].durability = new_durability
		_record_repair(equipped[slot].name, amount, new_durability)
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
		_record_equipment_change(slot, "%s +%s" % [eq.name, enchantment_id], true)
		emit_event("enchantment_added", {"slot": slot, "enchantment": enchantment_id})
		return true
	return false

func _record_equipment_change(slot: String, equipment_name: String, equipped: bool) -> void:
	var history = get_state("equipment_history", [])
	history.append({"slot": slot, "equipment": equipment_name, "equipped": equipped, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("equipment_history", history)

func _record_durability_change(equipment_name: String, durability: float) -> void:
	var tracking = get_state("durability_tracking", [])
	tracking.append({"equipment": equipment_name, "durability": durability, "time": Time.get_ticks_msec()})
	if tracking.size() > 50:
		tracking.pop_front()
	set_state("durability_tracking", tracking)

func _record_repair(equipment_name: String, amount_repaired: float, new_durability: float) -> void:
	var history = get_state("repair_history", [])
	history.append({"equipment": equipment_name, "amount": amount_repaired, "new_durability": new_durability, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("repair_history", history)

func _record_weight_change(weight: float) -> void:
	var history = get_state("weight_management_history", [])
	history.append({"weight": weight, "capacity_percent": (weight / get_state("carry_capacity", 50.0)) * 100.0, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("weight_management_history", history)

func update_equipment_statistics() -> void:
	var stats = get_state("equipment_statistics", {})
	var equipped = get_state("equipped", {})
	var equipped_count = 0
	for slot in equipped:
		if equipped[slot] != null:
			equipped_count += 1
	stats["equipment_equipped"] = equipped_count
	stats["total_weight"] = get_state("total_weight", 0.0)
	stats["carry_capacity"] = get_state("carry_capacity", 50.0)
	stats["equipment_changes"] = get_state("equipment_history", []).size()
	stats["repairs_made"] = get_state("repair_history", []).size()
	stats["total_damage"] = get_total_damage()
	stats["total_defense"] = get_total_defense()
	stats["durability_events"] = get_state("durability_tracking", []).size()
	stats["weight_changes"] = get_state("weight_management_history", []).size()
	stats["equipment_sets_registered"] = get_state("equipment_sets", {}).size()
	stats["active_set_bonuses"] = get_active_set_bonuses().size()
	stats["carrying_capacity_percent"] = get_carrying_capacity_percent()
	set_state("equipment_statistics", stats)

func get_equipment_statistics() -> Dictionary:
	update_equipment_statistics()
	return get_state("equipment_statistics", {})

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
