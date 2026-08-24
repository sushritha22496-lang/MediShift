extends Node3D

class_name InventorySystem

var items: Dictionary = {}
var max_slots: int = 20

signal item_added(item_name: String, count: int)
signal item_removed(item_name: String, count: int)
signal inventory_full

func _ready() -> void:
	pass

func add_item(item_name: String, quantity: int = 1) -> bool:
	if items.size() >= max_slots and not items.has(item_name):
		inventory_full.emit()
		return false

	if not items.has(item_name):
		items[item_name] = 0

	items[item_name] += quantity
	item_added.emit(item_name, quantity)
	return true

func remove_item(item_name: String, quantity: int = 1) -> bool:
	if not items.has(item_name):
		return false

	if items[item_name] < quantity:
		return false

	items[item_name] -= quantity

	if items[item_name] <= 0:
		items.erase(item_name)

	item_removed.emit(item_name, quantity)
	return true

func has_item(item_name: String, quantity: int = 1) -> bool:
	return items.get(item_name, 0) >= quantity

func get_item_count(item_name: String) -> int:
	return items.get(item_name, 0)

func get_inventory() -> Dictionary:
	return items.duplicate()

func clear_inventory() -> void:
	items.clear()

func get_inventory_display() -> String:
	if items.is_empty():
		return "Empty"

	var display = ""
	for item_name in items.keys():
		display += "%s: %d\n" % [item_name, items[item_name]]
	return display.strip_edges()
