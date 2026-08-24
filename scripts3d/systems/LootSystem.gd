extends Node3D

class_name LootSystem

class LootDrop:
	var item_name: String
	var quantity: int = 1
	var rarity: String = "common"
	var weight: float = 1.0

var loot_tables: Dictionary = {}

signal loot_dropped(item_name: String, quantity: int)

func _ready() -> void:
	_initialize_loot_tables()

func _initialize_loot_tables() -> void:
	var monkey_loot = [
		{"item": "Banana", "quantity": 1, "rarity": "common", "weight": 0.8},
		{"item": "Fruit", "quantity": 1, "rarity": "common", "weight": 0.6},
		{"item": "Monkey Fur", "quantity": 1, "rarity": "uncommon", "weight": 0.3},
	]

	var demon_loot = [
		{"item": "Gold Coin", "quantity": 5, "rarity": "uncommon", "weight": 0.7},
		{"item": "Demon Scale", "quantity": 1, "rarity": "rare", "weight": 0.4},
		{"item": "Dark Essence", "quantity": 1, "rarity": "rare", "weight": 0.2},
	]

	var scout_loot = [
		{"item": "Stone", "quantity": 1, "rarity": "common", "weight": 0.5},
		{"item": "Cloth", "quantity": 1, "rarity": "common", "weight": 0.4},
		{"item": "Herb", "quantity": 1, "rarity": "uncommon", "weight": 0.3},
	]

	loot_tables["monkey"] = monkey_loot
	loot_tables["demon"] = demon_loot
	loot_tables["scout"] = scout_loot

func get_loot_for_enemy(enemy_type: String) -> LootDrop:
	if not loot_tables.has(enemy_type):
		return null

	var table = loot_tables[enemy_type]
	var total_weight = 0.0

	for item in table:
		total_weight += item["weight"]

	var roll = randf() * total_weight
	var current_weight = 0.0

	for item in table:
		current_weight += item["weight"]
		if roll <= current_weight:
			var drop = LootDrop.new()
			drop.item_name = item["item"]
			drop.quantity = item.get("quantity", 1)
			drop.rarity = item.get("rarity", "common")
			drop.weight = item.get("weight", 1.0)
			return drop

	return null

func drop_loot(position: Vector3, enemy_type: String) -> void:
	var loot = get_loot_for_enemy(enemy_type)
	if loot:
		loot_dropped.emit(loot.item_name, loot.quantity)

func get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common": return Color.GRAY
		"uncommon": return Color.GREEN
		"rare": return Color.BLUE
		"epic": return Color.PURPLE
		"legendary": return Color.YELLOW
		_: return Color.WHITE
