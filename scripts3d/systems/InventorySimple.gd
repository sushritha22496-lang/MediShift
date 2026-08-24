extends BaseSystemSimple

class_name InventorySimple

const MAX_SLOTS = 20
const MAX_WEIGHT = 100.0
const DEFAULT_STACK_SIZE = 10

signal inventory_changed
signal inventory_full
signal weight_limit_exceeded

func _ready() -> void:
	var items = []
	items.resize(MAX_SLOTS)
	for i in range(MAX_SLOTS):
		items[i] = null
	set_state("items", items)
	set_state("total_weight", 0.0)
	set_state("slot_filter", "all")

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
			set_state("total_weight", current_weight + item_weight)
			inventory_changed.emit()
			emit_event("item_added", {"item": item_name, "qty": quantity, "rarity": rarity})
			return true
		elif items[i]["name"] == item_name and items[i]["quantity"] < DEFAULT_STACK_SIZE:
			var can_add = min(quantity, DEFAULT_STACK_SIZE - items[i]["quantity"])
			items[i]["quantity"] += can_add
			set_state("total_weight", current_weight + (weight * can_add))
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
			set_state("total_weight", maxf(0.0, get_state("total_weight", 0.0) - weight_removed))
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
