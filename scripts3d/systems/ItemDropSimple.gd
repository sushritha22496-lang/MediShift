extends BaseSystemSimple

class_name ItemDropSimple

class DroppedItem:
	var id: String
	var item_name: String
	var quantity: int
	var position: Vector3
	var lifetime: float
	var rarity: String
	func _init(p_id: String, p_name: String, p_qty: int, p_pos: Vector3, p_rarity: String = "common") -> void:
		id = p_id
		item_name = p_name
		quantity = p_qty
		position = p_pos
		lifetime = 300.0
		rarity = p_rarity

var dropped_items: Array[DroppedItem] = []

signal item_dropped(item: DroppedItem)
signal item_collected(item_id: String, quantity: int)

func _ready() -> void:
	set_state("total_items_dropped", 0)
	set_state("total_items_collected", 0)

func drop_item(item_name: String, quantity: int, position: Vector3, rarity: String = "common") -> DroppedItem:
	var id = "drop_%d" % randi()
	var item = DroppedItem.new(id, item_name, quantity, position, rarity)
	dropped_items.append(item)
	var total = get_state("total_items_dropped", 0)
	total += 1
	set_state("total_items_dropped", total)
	item_dropped.emit(item)
	emit_event("item_dropped", rarity)
	return item

func collect_item(item_id: String) -> int:
	for i in range(dropped_items.size()):
		if dropped_items[i].id == item_id:
			var qty = dropped_items[i].quantity
			dropped_items.remove_at(i)
			var total = get_state("total_items_collected", 0)
			total += 1
			set_state("total_items_collected", total)
			item_collected.emit(item_id, qty)
			emit_event("item_collected", item_id)
			return qty
	return 0

func get_items_in_range(position: Vector3, range: float) -> Array[DroppedItem]:
	var nearby: Array[DroppedItem] = []
	for item in dropped_items:
		if position.distance_to(item.position) <= range:
			nearby.append(item)
	return nearby

func get_nearest_item(position: Vector3) -> DroppedItem:
	var nearest: DroppedItem = null
	var min_distance = INF
	for item in dropped_items:
		var distance = position.distance_to(item.position)
		if distance < min_distance:
			min_distance = distance
			nearest = item
	return nearest

func get_dropped_items() -> Array[DroppedItem]:
	return dropped_items

func get_item_count() -> int:
	return dropped_items.size()

func get_drop_text() -> String:
	var text = "Item Drops\n"
	text += "Active: %d | Dropped: %d | Collected: %d" % [get_item_count(), get_state("total_items_dropped", 0), get_state("total_items_collected", 0)]
	return text
