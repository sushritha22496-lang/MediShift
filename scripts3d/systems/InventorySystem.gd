extends Node3D

class_name InventorySystem

enum ItemType { CONSUMABLE, WEAPON, ARMOR, QUEST_ITEM, MISCELLANEOUS }
enum ItemRarity { COMMON, UNCOMMON, RARE, LEGENDARY }

class Item:
	var name: String
	var type: ItemType
	var rarity: ItemRarity
	var description: String
	var quantity: int
	var stackable: bool
	var metadata: Dictionary

var items: Dictionary = {}
var equipment: Dictionary = {
	"head": null,
	"body": null,
	"hands": null,
	"feet": null,
	"main_hand": null,
	"off_hand": null
}
var max_slots: int = 30
var quest_items: Array[String] = []

signal item_added(item_name: String, count: int)
signal item_removed(item_name: String, count: int)
signal inventory_full
signal equipment_changed(slot: String, item_name: String)
signal quest_item_added(item_name: String)

func _ready() -> void:
	pass

func add_item(item_name: String, quantity: int = 1, item_type: ItemType = ItemType.MISCELLANEOUS,
			  rarity: ItemRarity = ItemRarity.COMMON, description: String = "") -> bool:
	if items.size() >= max_slots and not items.has(item_name):
		inventory_full.emit()
		return false

	if not items.has(item_name):
		var item = Item.new()
		item.name = item_name
		item.type = item_type
		item.rarity = rarity
		item.description = description
		item.quantity = quantity
		item.stackable = (item_type != ItemType.WEAPON and item_type != ItemType.ARMOR)
		item.metadata = {}
		items[item_name] = item
	else:
		items[item_name].quantity += quantity

	# Track quest items
	if item_type == ItemType.QUEST_ITEM and item_name not in quest_items:
		quest_items.append(item_name)
		quest_item_added.emit(item_name)

	item_added.emit(item_name, quantity)
	return true

func remove_item(item_name: String, quantity: int = 1) -> bool:
	if not items.has(item_name):
		return false

	if items[item_name].quantity < quantity:
		return false

	items[item_name].quantity -= quantity

	if items[item_name].quantity <= 0:
		items.erase(item_name)

	item_removed.emit(item_name, quantity)
	return true

func has_item(item_name: String, quantity: int = 1) -> bool:
	if not items.has(item_name):
		return false
	return items[item_name].quantity >= quantity

func get_item_count(item_name: String) -> int:
	if not items.has(item_name):
		return 0
	return items[item_name].quantity

func get_inventory() -> Dictionary:
	return items.duplicate()

func clear_inventory() -> void:
	items.clear()
	quest_items.clear()

func get_inventory_display() -> String:
	if items.is_empty():
		return "Empty"

	var display = ""
	for item_name in items.keys():
		var item = items[item_name]
		display += "%s (%s) [%s]: %d\n" % [item_name, _get_rarity_string(item.rarity), _get_type_string(item.type), item.quantity]
	return display.strip_edges()

func equip_item(slot: String, item_name: String) -> bool:
	if not equipment.has(slot) or not items.has(item_name):
		return false

	equipment[slot] = item_name
	equipment_changed.emit(slot, item_name)
	return true

func unequip_item(slot: String) -> bool:
	if not equipment.has(slot):
		return false

	equipment[slot] = null
	equipment_changed.emit(slot, "")
	return true

func get_equipped(slot: String) -> String:
	if equipment.has(slot):
		return equipment[slot] if equipment[slot] else ""
	return ""

func get_quest_items() -> Array[String]:
	return quest_items

func is_quest_item(item_name: String) -> bool:
	return item_name in quest_items

static func _get_type_string(type: ItemType) -> String:
	match type:
		ItemType.CONSUMABLE:
			return "Consumable"
		ItemType.WEAPON:
			return "Weapon"
		ItemType.ARMOR:
			return "Armor"
		ItemType.QUEST_ITEM:
			return "Quest"
		_:
			return "Misc"

static func _get_rarity_string(rarity: ItemRarity) -> String:
	match rarity:
		ItemRarity.COMMON:
			return "Common"
		ItemRarity.UNCOMMON:
			return "Uncommon"
		ItemRarity.RARE:
			return "Rare"
		ItemRarity.LEGENDARY:
			return "Legendary"
		_:
			return "Unknown"
