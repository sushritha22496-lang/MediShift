extends NPCSimple

class_name MerchantNPCSimple

@export var interaction_range: float = 5.0

var inventory: Dictionary = {}
var merchant_gold: float = 1000.0
var is_trading: bool = false

signal trade_completed(item: String, price: float)
signal shop_opened

func _ready() -> void:
	npc_name = "Merchant"
	add_to_group("npcs")
	approach_distance = interaction_range
	walk_speed = 0.0
	run_speed = 0.0
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

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	_play_anim("idle")
	velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)
	move_and_slide()

func open_shop(player: Node3D) -> void:
	if global_position.distance_to(player.global_position) > interaction_range:
		return
	is_trading = true
	shop_opened.emit()
	dialogue.emit("🏪 Welcome! What would you like to buy?")

func buy_item(player: Node3D, item_name: String) -> bool:
	if not item_name in inventory or inventory[item_name]["stock"] <= 0:
		return false
	var price = inventory[item_name]["price"]
	if player.has_method("add_to_inventory"):
		player.add_to_inventory(item_name, 1)
	inventory[item_name]["stock"] -= 1
	merchant_gold += price
	trade_completed.emit(item_name, price)
	dialogue.emit("✓ Transaction complete!")
	return true

func sell_item(player: Node3D, item_name: String, quantity: int = 1) -> bool:
	if not item_name in inventory or not player.has_method("remove_item"):
		return false
	if not player.remove_item(item_name, quantity):
		return false
	var sell_price = inventory[item_name]["price"] * quantity * 0.7
	inventory[item_name]["stock"] += quantity
	merchant_gold -= sell_price
	trade_completed.emit(item_name, sell_price)
	return true

func get_shop_text() -> String:
	var text = "🏪 %s's Shop:\n" % npc_name
	for item_name in inventory:
		var item = inventory[item_name]
		text += "%s - %d gold (Stock: %d)\n" % [item_name, item["price"], item["stock"]]
	return text

func close_shop() -> void:
	is_trading = false
	dialogue.emit("🏪 Come back soon!")
