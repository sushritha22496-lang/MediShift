extends Node3D

class_name MerchantNPCSimple

@export var merchant_name: String = "Merchant"
@export var shop_location: Vector3 = Vector3.ZERO
@export var interaction_range: float = 5.0

var inventory: Dictionary = {}
var gold: float = 1000.0
var is_trading: bool = false

@onready var model: Node3D = $Model
@onready var anim_player: AnimationPlayer = $Model/AnimationPlayer

signal merchant_dialogue(text: String)
signal trade_completed(item: String, price: float)
signal shop_opened

func _ready() -> void:
	add_to_group("npcs")
	shop_location = global_position
	_initialize_goods()

	if anim_player and anim_player.has_animation("idle"):
		anim_player.play("idle")

func _initialize_goods() -> void:
	inventory = {
		"Health Potion": {"price": 50, "stock": 10},
		"Mana Potion": {"price": 75, "stock": 8},
		"Bread": {"price": 10, "stock": 20},
		"Iron Sword": {"price": 150, "stock": 2},
		"Leather Armor": {"price": 100, "stock": 3}
	}

func open_shop(player: Node3D) -> void:
	var distance = global_position.distance_to(player.global_position)
	if distance > interaction_range:
		return

	is_trading = true
	shop_opened.emit()
	merchant_dialogue.emit("🏪 %s: Welcome! What would you like to buy?" % merchant_name)

func buy_item(player: Node3D, item_name: String) -> bool:
	if not item_name in inventory:
		return false

	var item = inventory[item_name]
	if item["stock"] <= 0:
		return false

	var price = item["price"]
	if player.has_method("add_gold"):
		var player_gold = player.get("gold") if player.has_meta("gold") else 0
		if player_gold < price:
			merchant_dialogue.emit("💰 Not enough gold!")
			return false

	item["stock"] -= 1
	gold += price

	if player.has_method("add_to_inventory"):
		player.add_to_inventory(item_name, 1)

	if player.has_method("add_gold"):
		player.add_gold(-price)

	trade_completed.emit(item_name, price)
	merchant_dialogue.emit("✓ Transaction complete!")
	return true

func sell_item(player: Node3D, item_name: String, quantity: int = 1) -> bool:
	if not item_name in inventory:
		return false

	if not player.has_method("remove_item"):
		return false

	if not player.remove_item(item_name, quantity):
		return false

	var sell_price = inventory[item_name]["price"] * quantity * 0.7
	inventory[item_name]["stock"] += quantity
	gold -= sell_price

	if player.has_method("add_gold"):
		player.add_gold(sell_price)

	trade_completed.emit(item_name, sell_price)
	return true

func get_shop_text() -> String:
	var text = "🏪 %s's Shop:\n" % merchant_name
	for item_name in inventory:
		var item = inventory[item_name]
		text += "%s - %d gold (Stock: %d)\n" % [item_name, item["price"], item["stock"]]
	return text

func close_shop() -> void:
	is_trading = false
	merchant_dialogue.emit("🏪 Come back soon!")
