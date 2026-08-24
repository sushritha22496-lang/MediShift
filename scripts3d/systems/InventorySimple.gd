extends Node

class_name InventorySimple

const MAX_SLOTS = 20
var items: Array = []

signal inventory_changed

func _ready() -> void:
	items.resize(MAX_SLOTS)
	for i in range(MAX_SLOTS):
		items[i] = null

func add_item(item_name: String, quantity: int = 1) -> bool:
	for i in range(MAX_SLOTS):
		if items[i] == null:
			items[i] = {"name": item_name, "quantity": quantity}
			inventory_changed.emit()
			return true
		elif items[i]["name"] == item_name:
			items[i]["quantity"] += quantity
			inventory_changed.emit()
			return true
	return false

func remove_item(item_name: String, quantity: int = 1) -> bool:
	for i in range(MAX_SLOTS):
		if items[i] != null and items[i]["name"] == item_name:
			items[i]["quantity"] -= quantity
			if items[i]["quantity"] <= 0:
				items[i] = null
			inventory_changed.emit()
			return true
	return false

func get_item_count(item_name: String) -> int:
	for item in items:
		if item != null and item["name"] == item_name:
			return item["quantity"]
	return 0

func get_inventory_text() -> String:
	var text = "Inventory:\n"
	for item in items:
		if item != null:
			text += "%s x%d\n" % [item["name"], item["quantity"]]
	if text == "Inventory:\n":
		text = "Inventory: Empty"
	return text
