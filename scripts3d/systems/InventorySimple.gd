extends BaseSystemSimple

class_name InventorySimple

const MAX_SLOTS = 20
const MAX_WEIGHT = 100.0
const DEFAULT_STACK_SIZE = 10

signal inventory_changed
signal inventory_full
signal weight_limit_exceeded
signal equipment_changed(slot: String, item: String)

func _ready() -> void:
	var items = []
	items.resize(MAX_SLOTS)
	for i in range(MAX_SLOTS):
		items[i] = null
	set_state("items", items)
	set_state("total_weight", 0.0)
	set_state("slot_filter", "all")
	set_state("equipment_slots", {"head": null, "body": null, "hands": null, "feet": null, "back": null})
	set_state("item_conditions", {})
	set_state("favorite_items", [])
	set_state("locked_items", [])
	set_state("item_addition_history", [])
	set_state("item_removal_history", [])
	set_state("weight_change_history", [])
	set_state("inventory_statistics", {})

func _record_item_addition(item_name: String, quantity: int, rarity: String, weight: float) -> void:
	var history = get_state("item_addition_history", [])
	history.append({"item": item_name, "quantity": quantity, "rarity": rarity, "weight": weight, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("item_addition_history", history)

func _record_item_removal(item_name: String, quantity: int) -> void:
	var history = get_state("item_removal_history", [])
	history.append({"item": item_name, "quantity": quantity, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("item_removal_history", history)

func _record_weight_change(new_weight: float) -> void:
	var history = get_state("weight_change_history", [])
	history.append({"weight": new_weight, "capacity_percent": (new_weight / MAX_WEIGHT) * 100.0, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("weight_change_history", history)

func add_item(item_name: String, quantity: int = 1, rarity: String = "common", weight: float = 1.0) -> bool:
	var items = get_state("items", [])
	var current_weight = get_state("total_weight", 0.0)
	var item_weight = weight * quantity
	if current_weight + item_weight > MAX_WEIGHT:
		weight_limit_exceeded.emit()
		return false
	for i in range(MAX_SLOTS):
		if items[i] == null:
			items[i] = {"name": item_name, "quantity": quantity, "rarity": rarity, "weight": weight, "durability": 100.0}
			var new_weight = current_weight + item_weight
			set_state("total_weight", new_weight)
			_record_item_addition(item_name, quantity, rarity, weight)
			_record_weight_change(new_weight)
			inventory_changed.emit()
			emit_event("item_added", {"item": item_name, "qty": quantity, "rarity": rarity})
			return true
		elif items[i]["name"] == item_name and items[i]["quantity"] < DEFAULT_STACK_SIZE:
			var can_add = min(quantity, DEFAULT_STACK_SIZE - items[i]["quantity"])
			items[i]["quantity"] += can_add
			var new_weight = current_weight + (weight * can_add)
			set_state("total_weight", new_weight)
			_record_item_addition(item_name, can_add, rarity, weight)
			_record_weight_change(new_weight)
			inventory_changed.emit()
			if can_add < quantity:
				return add_item(item_name, quantity - can_add, rarity, weight)
			return true
	inventory_full.emit()
	return false

func remove_item(item_name: String, quantity: int = 1) -> bool:
	var items = get_state("items", [])
	for i in range(MAX_SLOTS):
		if items[i] != null and items[i]["name"] == item_name:
			var weight_removed = items[i]["weight"] * quantity
			var new_weight = maxf(0.0, get_state("total_weight", 0.0) - weight_removed)
			set_state("total_weight", new_weight)
			_record_item_removal(item_name, quantity)
			_record_weight_change(new_weight)
			items[i]["quantity"] -= quantity
			if items[i]["quantity"] <= 0:
				items[i] = null
			inventory_changed.emit()
			emit_event("item_removed", {"item": item_name, "qty": quantity})
			return true
	return false

func get_item_count(item_name: String) -> int:
	var items = get_state("items", [])
	for item in items:
		if item != null and item["name"] == item_name:
			return item["quantity"]
	return 0

func get_inventory_weight_percent() -> float:
	var weight = get_state("total_weight", 0.0)
	return (weight / MAX_WEIGHT) * 100.0

func sort_by_rarity() -> Array:
	var items = get_state("items", [])
	var sorted = items.filter(func(i): return i != null)
	sorted.sort_custom(func(a, b): return (a.get("rarity", "common") > b.get("rarity", "common")))
	return sorted

func get_inventory_text() -> String:
	var items = get_state("items", [])
	var weight_pct = get_inventory_weight_percent()
	var text = "Inventory (%.0f/%.0f kg):\n" % [get_state("total_weight", 0.0), MAX_WEIGHT]
	for item in items:
		if item != null:
			var durability = " [Dur: %.0f%%]" % item.get("durability", 100.0) if item.get("durability", 100.0) < 100.0 else ""
			text += "%s x%d (%s)%s\n" % [item["name"], item["quantity"], item.get("rarity", "common"), durability]
	return text if text != ("Inventory (%.0f/%.0f kg):\n" % [get_state("total_weight", 0.0), MAX_WEIGHT]) else "Inventory: Empty"

func damage_item(item_name: String, damage: float) -> void:
	var items = get_state("items", [])
	for item in items:
		if item != null and item["name"] == item_name:
			item["durability"] = maxf(0.0, item.get("durability", 100.0) - damage)
			emit_event("item_damaged", item_name)

func equip_to_slot(item_name: String, slot: String) -> bool:
	var valid_slots = ["head", "body", "hands", "feet", "back"]
	if slot not in valid_slots or not has_item(item_name):
		return false
	var equipment = get_state("equipment_slots", {})
	equipment[slot] = item_name
	set_state("equipment_slots", equipment)
	equipment_changed.emit(slot, item_name)
	emit_event("item_equipped", {"item": item_name, "slot": slot})
	return true

func unequip_slot(slot: String) -> void:
	var equipment = get_state("equipment_slots", {})
	if slot in equipment:
		equipment[slot] = null
		set_state("equipment_slots", equipment)
		emit_event("item_unequipped", slot)

func has_item(item_name: String) -> bool:
	return get_item_count(item_name) > 0

func get_equipped_item(slot: String) -> String:
	var equipment = get_state("equipment_slots", {})
	return equipment.get(slot, null)

func filter_by_type(item_type: String) -> Array:
	var items = get_state("items", [])
	var filtered = []
	for item in items:
		if item != null and item.get("type", "") == item_type:
			filtered.append(item)
	return filtered

func mark_favorite(item_name: String) -> void:
	var favorites = get_state("favorite_items", [])
	if item_name not in favorites:
		favorites.append(item_name)
		set_state("favorite_items", favorites)
		emit_event("marked_favorite", item_name)

func lock_item(item_name: String) -> void:
	var locked = get_state("locked_items", [])
	if item_name not in locked:
		locked.append(item_name)
		set_state("locked_items", locked)

func set_item_condition(item_name: String, condition: float) -> void:
	var conditions = get_state("item_conditions", {})
	conditions[item_name] = clampf(condition, 0.0, 100.0)
	set_state("item_conditions", conditions)

func update_inventory_statistics() -> void:
	var stats = get_state("inventory_statistics", {})
	var items = get_state("items", [])
	var add_hist = get_state("item_addition_history", [])
	var remove_hist = get_state("item_removal_history", [])
	var weight_hist = get_state("weight_change_history", [])
	var item_count = 0
	var unique_items = {}
	for item in items:
		if item != null:
			item_count += item["quantity"]
			unique_items[item["name"]] = true
	stats["total_items"] = item_count
	stats["unique_items"] = unique_items.size()
	stats["inventory_slots_used"] = 0
	for item in items:
		if item != null:
			stats["inventory_slots_used"] += 1
	stats["current_weight"] = get_state("total_weight", 0.0)
	stats["weight_percent"] = get_inventory_weight_percent()
	stats["total_additions"] = add_hist.size()
	stats["total_removals"] = remove_hist.size()
	stats["favorite_items"] = get_state("favorite_items", []).size()
	stats["locked_items"] = get_state("locked_items", []).size()
	var equipped = get_state("equipment_slots", {})
	var equipped_count = 0
	for slot in equipped:
		if equipped[slot] != null:
			equipped_count += 1
	stats["equipment_slots_filled"] = equipped_count
	set_state("inventory_statistics", stats)

func get_inventory_statistics() -> Dictionary:
	update_inventory_statistics()
	return get_state("inventory_statistics", {})
