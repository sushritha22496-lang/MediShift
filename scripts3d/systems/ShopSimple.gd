extends BaseSystemSimple

class_name ShopSimple

class ShopItem:
	var id: String
	var name: String
	var price: float
	var stock: int
	var item_type: String
	func _init(p_id: String, p_name: String, p_price: float, p_stock: int = -1, p_type: String = "item") -> void:
		id = p_id
		name = p_name
		price = p_price
		stock = p_stock
		item_type = p_type

var shops: Dictionary = {}
var current_shop: String = ""

signal shop_opened(shop_id: String)
signal item_purchased(shop_id: String, item_id: String, price: float)
signal item_sold(shop_id: String, item_id: String, price: float)
signal shop_closed

func _ready() -> void:
	set_state("transaction_history", [])
	_initialize_shops()

func _initialize_shops() -> void:
	shops["general"] = [
		ShopItem.new("health_potion", "Health Potion", 25.0, -1, "potion"),
		ShopItem.new("mana_potion", "Mana Potion", 20.0, -1, "potion"),
		ShopItem.new("bread", "Bread", 5.0, -1, "food"),
		ShopItem.new("rope", "Rope", 10.0, -1, "tool")
	]
	shops["weapons"] = [
		ShopItem.new("wooden_sword", "Wooden Sword", 50.0, -1, "weapon"),
		ShopItem.new("iron_sword", "Iron Sword", 150.0, -1, "weapon"),
		ShopItem.new("bow", "Bow", 100.0, -1, "weapon")
	]
	shops["armor"] = [
		ShopItem.new("leather_helm", "Leather Helm", 30.0, -1, "armor"),
		ShopItem.new("iron_chest", "Iron Chest", 120.0, -1, "armor"),
		ShopItem.new("steel_legs", "Steel Legs", 150.0, -1, "armor")
	]
	shops["rare"] = [
		ShopItem.new("enchanted_gem", "Enchanted Gem", 500.0, 5, "rare"),
		ShopItem.new("rare_scroll", "Rare Scroll", 300.0, 10, "rare")
	]

func open_shop(shop_id: String) -> bool:
	if shop_id in shops:
		current_shop = shop_id
		shop_opened.emit(shop_id)
		emit_event("shop_opened", shop_id)
		return true
	return false

func close_shop() -> void:
	current_shop = ""
	shop_closed.emit()
	emit_event("shop_closed", "")

func purchase_item(shop_id: String, item_id: String, gold: float) -> bool:
	var shop_items = shops.get(shop_id, [])
	for item in shop_items:
		if item.id == item_id:
			if gold >= item.price:
				if item.stock != -1:
					if item.stock > 0:
						item.stock -= 1
					else:
						return false
				_log_transaction("purchase", shop_id, item_id, item.price)
				item_purchased.emit(shop_id, item_id, item.price)
				emit_event("item_purchased", item_id)
				return true
			return false
	return false

func sell_item(shop_id: String, item_id: String) -> float:
	var shop_items = shops.get(shop_id, [])
	for item in shop_items:
		if item.id == item_id:
			var sell_price = item.price * 0.5
			if item.stock != -1:
				item.stock += 1
			_log_transaction("sell", shop_id, item_id, sell_price)
			item_sold.emit(shop_id, item_id, sell_price)
			emit_event("item_sold", item_id)
			return sell_price
	return 0.0

func get_shop_items(shop_id: String) -> Array[ShopItem]:
	return shops.get(shop_id, [])

func get_item_price(shop_id: String, item_id: String) -> float:
	var shop_items = shops.get(shop_id, [])
	for item in shop_items:
		if item.id == item_id:
			return item.price
	return 0.0

func get_shop_text(shop_id: String) -> String:
	var text = "Shop: %s\n" % shop_id.capitalize()
	var items = get_shop_items(shop_id)
	for item in items:
		var stock_str = "✓" if item.stock == -1 or item.stock > 0 else "✗"
		text += "%s %s - %.0f gold\n" % [stock_str, item.name, item.price]
	return text

func _log_transaction(type: String, shop_id: String, item_id: String, amount: float) -> void:
	var history = get_state("transaction_history", [])
	history.append({
		"type": type,
		"shop": shop_id,
		"item": item_id,
		"amount": amount,
		"timestamp": get_tree().get_frame()
	})
	set_state("transaction_history", history)
