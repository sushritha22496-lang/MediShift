extends BaseSystemSimple

class_name LootSimple

class LootDrop:
	var item_name: String
	var quantity: int
	var rarity: String
	var value: float
	var level_requirement: int
	var is_crafting_material: bool
	var set_name: String
	var properties: Dictionary
	var unique: bool
	func _init(p_name: String, p_qty: int, p_rarity: String, p_value: float, p_level: int = 1, p_material: bool = false) -> void:
		item_name = p_name
		quantity = p_qty
		rarity = p_rarity
		value = p_value
		level_requirement = p_level
		is_crafting_material = p_material
		set_name = ""
		properties = {}
		unique = p_rarity == "epic"

var loot_table: Dictionary = {
	"common": [
		LootDrop.new("Copper Coin", 1, "common", 5),
		LootDrop.new("Bread", 1, "common", 10),
		LootDrop.new("Wood", 2, "common", 3)
	],
	"uncommon": [
		LootDrop.new("Silver Coin", 1, "uncommon", 25),
		LootDrop.new("Health Potion", 1, "uncommon", 50),
		LootDrop.new("Leather Armor", 1, "uncommon", 100)
	],
	"rare": [
		LootDrop.new("Gold Coin", 1, "rare", 100),
		LootDrop.new("Mana Potion", 1, "rare", 75),
		LootDrop.new("Iron Sword", 1, "rare", 200)
	],
	"epic": [
		LootDrop.new("Ancient Artifact", 1, "epic", 500),
		LootDrop.new("Divine Blessing", 1, "epic", 250),
		LootDrop.new("Enchanted Weapon", 1, "epic", 1000)
	]
}

signal loot_generated(drop: LootDrop)
signal guaranteed_drop(drop: LootDrop)

func _ready() -> void:
	set_state("guaranteed_pity", 0)
	set_state("loot_history", [])
	set_state("rarity_distribution", {})
	set_state("value_tracking", [])
	set_state("crafting_material_tracking", {})
	set_state("set_item_tracking", [])
	set_state("pity_system_history", [])
	set_state("loot_drop_statistics", {})

func generate_loot(enemy_level: int = 1, is_boss: bool = false) -> LootDrop:
	var rarity_roll = randf()
	var pity = get_state("guaranteed_pity", 0)
	var rarity = "common"
	if pity >= 19:
		rarity = "epic"
		set_state("guaranteed_pity", 0)
	elif pity >= 9:
		rarity = "rare"
		set_state("guaranteed_pity", 0)
	else:
		var epic_threshold = 0.98 if is_boss else 0.95
		rarity = "epic" if rarity_roll > epic_threshold else ("rare" if rarity_roll > 0.8 else ("uncommon" if rarity_roll > 0.4 else "common"))
	var loot_list = loot_table.get(rarity, [])
	var drop = loot_list[randi() % loot_list.size()] if not loot_list.is_empty() else LootDrop.new("Gold Coin", 1, "common", 10)
	drop.value *= 1.0 + (enemy_level * 0.1)
	drop.quantity = int(drop.quantity * (1.0 + (enemy_level * 0.05)))
	var new_pity = pity + 1
	set_state("guaranteed_pity", new_pity)
	_record_loot_drop(rarity, drop)
	_track_rarity_distribution(rarity)
	_track_value(drop.value * drop.quantity)
	_track_pity_history(new_pity)
	if drop.is_crafting_material:
		_track_crafting_material(drop.item_name)
	loot_generated.emit(drop)
	emit_event("loot_generated", rarity)
	return drop

func get_loot_by_rarity(rarity: String) -> LootDrop:
	var loot_list = loot_table.get(rarity, [])
	return loot_list[randi() % loot_list.size()] if not loot_list.is_empty() else LootDrop.new("Gold Coin", 1, "common", 10)

func get_total_value(drops: Array[LootDrop]) -> float:
	var total = 0.0
	for drop in drops:
		total += drop.value * drop.quantity
	return total

func add_loot_table(rarity: String, drops: Array[LootDrop]) -> void:
	if not rarity in loot_table:
		loot_table[rarity] = []
	loot_table[rarity].append_array(drops)

func generate_set_bonus_item(set_name: String, rarity: String) -> LootDrop:
	var drop = LootDrop.new("Set Item - %s" % set_name, 1, rarity, 100 * (["common", "uncommon", "rare", "epic"].find(rarity) + 1))
	drop.set_name = set_name
	drop.properties["set_bonus_pieces"] = randi_range(2, 4)
	_track_set_item(set_name, rarity)
	_track_rarity_distribution(rarity)
	return drop

func _record_loot_drop(rarity: String, drop: LootDrop) -> void:
	var history = get_state("loot_history", [])
	history.append({"rarity": rarity, "item": drop.item_name, "value": drop.value, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("loot_history", history)

func _track_rarity_distribution(rarity: String) -> void:
	var dist = get_state("rarity_distribution", {})
	dist[rarity] = dist.get(rarity, 0) + 1
	set_state("rarity_distribution", dist)

func _track_value(value: float) -> void:
	var tracking = get_state("value_tracking", [])
	tracking.append({"value": value, "time": Time.get_ticks_msec()})
	if tracking.size() > 50:
		tracking.pop_front()
	set_state("value_tracking", tracking)

func _track_crafting_material(material_name: String) -> void:
	var tracking = get_state("crafting_material_tracking", {})
	tracking[material_name] = tracking.get(material_name, 0) + 1
	set_state("crafting_material_tracking", tracking)

func _track_set_item(set_name: String, rarity: String) -> void:
	var tracking = get_state("set_item_tracking", [])
	tracking.append({"set": set_name, "rarity": rarity, "time": Time.get_ticks_msec()})
	if tracking.size() > 50:
		tracking.pop_front()
	set_state("set_item_tracking", tracking)

func _track_pity_history(pity_count: int) -> void:
	var history = get_state("pity_system_history", [])
	history.append({"pity": pity_count, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("pity_system_history", history)

func update_loot_drop_statistics() -> void:
	var stats = get_state("loot_drop_statistics", {})
	var dist = get_state("rarity_distribution", {})
	stats["total_drops"] = get_state("loot_history", []).size()
	stats["rarity_breakdown"] = dist
	stats["total_value_tracked"] = get_state("value_tracking", []).size()
	stats["crafting_materials_found"] = get_state("crafting_material_tracking", {}).size()
	stats["set_items_found"] = get_state("set_item_tracking", []).size()
	stats["current_pity"] = get_state("guaranteed_pity", 0)
	var value_tracking = get_state("value_tracking", [])
	var total_value = 0.0
	for entry in value_tracking:
		total_value += entry["value"]
	stats["total_loot_value"] = total_value
	stats["average_loot_value"] = total_value / float(value_tracking.size()) if not value_tracking.is_empty() else 0.0
	set_state("loot_drop_statistics", stats)

func get_loot_history() -> Array:
	return get_state("loot_history", [])

func get_loot_statistics() -> Dictionary:
	update_loot_drop_statistics()
	return get_state("loot_drop_statistics", {})
