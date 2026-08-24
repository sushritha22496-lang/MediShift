extends Node

class_name EnchantmentSimple

class Enchantment:
	var id: String
	var name: String
	var power: float
	var cost: float
	var bonus_type: String

	func _init(p_id: String, p_name: String, p_power: float, p_cost: float, p_bonus: String) -> void:
		id = p_id
		name = p_name
		power = p_power
		cost = p_cost
		bonus_type = p_bonus

var available_enchantments: Array[Enchantment] = []
var enchanted_items: Dictionary = {}

signal enchantment_applied(equipment: String, enchantment: Enchantment)
signal enchantment_failed(reason: String)

func _ready() -> void:
	_initialize_enchantments()

func _initialize_enchantments() -> void:
	available_enchantments.append(Enchantment.new("sharpness", "Sharpness", 10.0, 500, "damage"))
	available_enchantments.append(Enchantment.new("hardness", "Hardness", 8.0, 450, "defense"))
	available_enchantments.append(Enchantment.new("swiftness", "Swiftness", 15.0, 600, "speed"))
	available_enchantments.append(Enchantment.new("regeneration", "Regeneration", 12.0, 700, "healing"))

func enchant_item(item_name: String, enchantment_id: String, gold_available: float) -> bool:
	var enchantment = _find_enchantment(enchantment_id)
	if not enchantment:
		enchantment_failed.emit("Enchantment not found")
		return false

	if gold_available < enchantment.cost:
		enchantment_failed.emit("Not enough gold")
		return false

	if not item_name in enchanted_items:
		enchanted_items[item_name] = []

	enchanted_items[item_name].append(enchantment)
	enchantment_applied.emit(item_name, enchantment)
	print("✨ Enchanted %s with %s" % [item_name, enchantment.name])
	return true

func _find_enchantment(enchantment_id: String) -> Enchantment:
	for ench in available_enchantments:
		if ench.id == enchantment_id:
			return ench
	return null

func get_item_enchantments(item_name: String) -> Array:
	return enchanted_items.get(item_name, [])

func get_enchantment_bonus(item_name: String, bonus_type: String) -> float:
	var total = 0.0
	var enchantments = get_item_enchantments(item_name)
	for ench in enchantments:
		if ench.bonus_type == bonus_type:
			total += ench.power
	return total

func get_enchantments_text() -> String:
	var text = "Available Enchantments:\n"
	for ench in available_enchantments:
		text += "%s (%d gold)\n" % [ench.name, int(ench.cost)]
	return text

func get_available_enchantments() -> Array[Enchantment]:
	return available_enchantments
