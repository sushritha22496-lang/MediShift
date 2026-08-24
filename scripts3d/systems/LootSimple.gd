extends Node

class_name LootSimple

class LootDrop:
	var item_name: String
	var quantity: int
	var rarity: String
	var value: float

	func _init(p_name: String, p_qty: int, p_rarity: String, p_value: float) -> void:
		item_name = p_name
		quantity = p_qty
		rarity = p_rarity
		value = p_value

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

func generate_loot(enemy_level: int = 1) -> LootDrop:
	var rarity_roll = randf()
	var rarity = "common"

	if rarity_roll > 0.8:
		rarity = "epic"
	elif rarity_roll > 0.6:
		rarity = "rare"
	elif rarity_roll > 0.3:
		rarity = "uncommon"

	var loot_list = loot_table.get(rarity, [])
	if loot_list.is_empty():
		return LootDrop.new("Gold Coin", 1, "common", 10)

	var drop = loot_list[randi() % loot_list.size()]
	loot_generated.emit(drop)
	return drop

func get_loot_by_rarity(rarity: String) -> LootDrop:
	var loot_list = loot_table.get(rarity, [])
	if loot_list.is_empty():
		return LootDrop.new("Gold Coin", 1, "common", 10)
	return loot_list[randi() % loot_list.size()]

func get_total_value(drops: Array[LootDrop]) -> float:
	var total = 0.0
	for drop in drops:
		total += drop.value * drop.quantity
	return total

func add_loot_table(rarity: String, drops: Array[LootDrop]) -> void:
	if not rarity in loot_table:
		loot_table[rarity] = []
	loot_table[rarity].append_array(drops)
