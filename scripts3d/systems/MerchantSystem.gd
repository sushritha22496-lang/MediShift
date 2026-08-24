extends Node3D

class_name MerchantSystem

class Item:
	var id: String
	var name: String
	var price: int
	var quantity: int = 1
	var rarity: String = "common"

class Merchant:
	var id: String
	var name: String
	var location: String
	var inventory: Array[Item] = []
	var gold: int = 1000

var merchants: Dictionary = {}

signal item_purchased(item: Item, buyer: String)
signal item_sold(item: Item, seller: String)
signal transaction_failed(reason: String)

func _ready() -> void:
	_initialize_merchants()

func _initialize_merchants() -> void:
	var village_merchant = Merchant.new()
	village_merchant.id = "village_merchant"
	village_merchant.name = "Village Merchant"
	village_merchant.location = "Badrachalam Village"

	var mango = Item.new()
	mango.id = "mango"
	mango.name = "Mango"
	mango.price = 10
	mango.quantity = 50

	var herb = Item.new()
	herb.id = "herb"
	herb.name = "Healing Herb"
	herb.price = 25
	herb.quantity = 20

	village_merchant.inventory.append(mango)
	village_merchant.inventory.append(herb)

	merchants["village_merchant"] = village_merchant

func buy_item(merchant_id: String, item_id: String, player_gold: int) -> bool:
	if not merchants.has(merchant_id):
		transaction_failed.emit("Merchant not found")
		return false

	var merchant = merchants[merchant_id]
	var item = _find_item_in_inventory(merchant.inventory, item_id)

	if item == null:
		transaction_failed.emit("Item not in stock")
		return false

	if item.price > player_gold:
		transaction_failed.emit("Not enough gold")
		return false

	if item.quantity <= 0:
		transaction_failed.emit("Item out of stock")
		return false

	item.quantity -= 1
	merchant.gold += item.price

	item_purchased.emit(item, merchant.name)
	return true

func sell_item(merchant_id: String, item: Item) -> int:
	if not merchants.has(merchant_id):
		transaction_failed.emit("Merchant not found")
		return 0

	var merchant = merchants[merchant_id]
	var sell_price = int(item.price * 0.7)

	var merchant_item = _find_item_in_inventory(merchant.inventory, item.id)
	if merchant_item:
		merchant_item.quantity += item.quantity
	else:
		var new_item = Item.new()
		new_item.id = item.id
		new_item.name = item.name
		new_item.price = item.price
		new_item.quantity = item.quantity
		merchant.inventory.append(new_item)

	merchant.gold -= sell_price

	item_sold.emit(item, merchant.name)
	return sell_price

func get_merchant(merchant_id: String) -> Merchant:
	return merchants.get(merchant_id, null)

func get_merchant_inventory(merchant_id: String) -> Array[Item]:
	if not merchants.has(merchant_id):
		return []
	return merchants[merchant_id].inventory

func get_item_price(merchant_id: String, item_id: String) -> int:
	var item = _find_item_in_inventory(get_merchant_inventory(merchant_id), item_id)
	if item:
		return item.price
	return 0

func _find_item_in_inventory(inventory: Array[Item], item_id: String) -> Item:
	for item in inventory:
		if item.id == item_id:
			return item
	return null

func get_all_merchants() -> Dictionary:
	return merchants.duplicate()
