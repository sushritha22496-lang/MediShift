extends Node3D

class_name MerchantSimple

@export var merchant_name: String = "Merchant"
@export var interact_range: float = 5.0

var goods: Dictionary = {
	"Health Potion": {"price": 50, "quantity": 10},
	"Mana Potion": {"price": 75, "quantity": 10},
	"Armor": {"price": 200, "quantity": 3},
	"Sword": {"price": 150, "quantity": 2},
	"Bread": {"price": 10, "quantity": 50}
}

signal merchant_interact
signal item_purchased(item_name: String, quantity: int, price: float)
signal item_sold(item_name: String, quantity: int, gold_received: float)

var purchase_history: Array = []
var sale_history: Array = []
var interaction_history: Array = []
var total_gold_earned: float = 0.0
var total_gold_spent: float = 0.0

func _record_purchase(item_name: String, quantity: int, price: float) -> void:
	purchase_history.append({"item": item_name, "quantity": quantity, "price": price, "time": Time.get_ticks_msec()})
	if purchase_history.size() > 50:
		purchase_history.pop_front()
	total_gold_earned += price

func _record_sale(item_name: String, quantity: int, price: float) -> void:
	sale_history.append({"item": item_name, "quantity": quantity, "price": price, "time": Time.get_ticks_msec()})
	if sale_history.size() > 50:
		sale_history.pop_front()
	total_gold_spent += price

func buy_item(buyer: Node3D, item_name: String, quantity: int = 1) -> bool:
	if not item_name in goods:
		return false

	var item = goods[item_name]
	if item["quantity"] < quantity:
		return false

	var total_price = item["price"] * quantity
	var gold = buyer.get("gold") if buyer.has_method("get") else 0

	if gold < total_price:
		return false

	item["quantity"] -= quantity

	if buyer.has_method("add_to_inventory"):
		buyer.add_to_inventory(item_name, quantity)

	if buyer.has_method("add_gold"):
		buyer.add_gold(-total_price)

	_record_purchase(item_name, quantity, total_price)
	item_purchased.emit(item_name, quantity, total_price)
	return true

func sell_item(seller: Node3D, item_name: String, quantity: int = 1) -> bool:
	if not seller.has_method("remove_item"):
		return false

	if not seller.remove_item(item_name, quantity):
		return false

	var sell_price = goods.get(item_name, {}).get("price", 10) * quantity * 0.8
	goods[item_name]["quantity"] += quantity

	if seller.has_method("add_gold"):
		seller.add_gold(sell_price)

	_record_sale(item_name, quantity, sell_price)
	item_sold.emit(item_name, quantity, sell_price)
	return true

func get_goods_text() -> String:
	var text = "%s's Goods:\n" % merchant_name
	for item_name in goods:
		var item = goods[item_name]
		text += "%s - %d gold (Stock: %d)\n" % [item_name, item["price"], item["quantity"]]
	return text

func interact(player: Node3D) -> void:
	var distance = global_position.distance_to(player.global_position)
	if distance < interact_range:
		interaction_history.append({"player": player.name, "time": Time.get_ticks_msec()})
		if interaction_history.size() > 50:
			interaction_history.pop_front()
		merchant_interact.emit()

func get_merchant_statistics() -> Dictionary:
	return {
		"total_purchases": purchase_history.size(),
		"total_sales": sale_history.size(),
		"total_interactions": interaction_history.size(),
		"gold_earned_from_sales": total_gold_earned,
		"gold_spent_on_buybacks": total_gold_spent,
		"unique_goods_available": goods.size()
	}
