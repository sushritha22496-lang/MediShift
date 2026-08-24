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
	set_state("drop_history", [])
	set_state("rarity_distribution", {})
	set_state("collection_effectiveness", [])
	set_state("item_tracking", {})
	set_state("drop_location_clustering", [])
	set_state("item_drop_statistics", {})

func drop_item(item_name: String, quantity: int, position: Vector3, rarity: String = "common") -> DroppedItem:
	var id = "drop_%d" % randi()
	var item = DroppedItem.new(id, item_name, quantity, position, rarity)
	dropped_items.append(item)
	var total = get_state("total_items_dropped", 0)
	total += 1
	set_state("total_items_dropped", total)
	_record_drop_history(item_name, quantity, rarity, position)
	_track_rarity_distribution(rarity)
	_update_item_tracking(item_name, quantity)
	_cluster_drop_location(position)
	item_dropped.emit(item)
	emit_event("item_dropped", rarity)
	return item

func collect_item(item_id: String) -> int:
	for i in range(dropped_items.size()):
		if dropped_items[i].id == item_id:
			var qty = dropped_items[i].quantity
			var item_name = dropped_items[i].item_name
			dropped_items.remove_at(i)
			var total = get_state("total_items_collected", 0)
			total += 1
			set_state("total_items_collected", total)
			_record_collection_effectiveness(item_name, qty)
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

func _record_drop_history(item_name: String, quantity: int, rarity: String, position: Vector3) -> void:
	var history = get_state("drop_history", [])
	history.append({"item": item_name, "qty": quantity, "rarity": rarity, "pos": position, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("drop_history", history)

func _track_rarity_distribution(rarity: String) -> void:
	var dist = get_state("rarity_distribution", {})
	dist[rarity] = dist.get(rarity, 0) + 1
	set_state("rarity_distribution", dist)

func _update_item_tracking(item_name: String, quantity: int) -> void:
	var tracking = get_state("item_tracking", {})
	if item_name not in tracking:
		tracking[item_name] = {"dropped": 0, "collected": 0}
	tracking[item_name]["dropped"] += quantity
	set_state("item_tracking", tracking)

func _cluster_drop_location(position: Vector3) -> void:
	var clustering = get_state("drop_location_clustering", [])
	clustering.append({"position": position, "time": Time.get_ticks_msec()})
	if clustering.size() > 50:
		clustering.pop_front()
	set_state("drop_location_clustering", clustering)

func _record_collection_effectiveness(item_name: String, quantity: int) -> void:
	var effectiveness = get_state("collection_effectiveness", [])
	effectiveness.append({"item": item_name, "qty": quantity, "time": Time.get_ticks_msec()})
	if effectiveness.size() > 50:
		effectiveness.pop_front()
	set_state("collection_effectiveness", effectiveness)
	var tracking = get_state("item_tracking", {})
	if item_name in tracking:
		tracking[item_name]["collected"] += quantity
	set_state("item_tracking", tracking)

func get_rarity_count(rarity: String) -> int:
	var dist = get_state("rarity_distribution", {})
	return dist.get(rarity, 0)

func get_most_common_rarity() -> String:
	var dist = get_state("rarity_distribution", {})
	var max_rarity = ""
	var max_count = 0
	for rarity in dist:
		if dist[rarity] > max_count:
			max_count = dist[rarity]
			max_rarity = rarity
	return max_rarity

func get_item_drop_count(item_name: String) -> int:
	var tracking = get_state("item_tracking", {})
	if item_name in tracking:
		return tracking[item_name]["dropped"]
	return 0

func get_item_collection_count(item_name: String) -> int:
	var tracking = get_state("item_tracking", {})
	if item_name in tracking:
		return tracking[item_name]["collected"]
	return 0

func get_drop_history() -> Array:
	return get_state("drop_history", [])

func update_item_drop_statistics() -> void:
	var stats = get_state("item_drop_statistics", {})
	stats["total_dropped"] = get_state("total_items_dropped", 0)
	stats["total_collected"] = get_state("total_items_collected", 0)
	stats["most_common_rarity"] = get_most_common_rarity()
	stats["active_drops"] = get_item_count()
	set_state("item_drop_statistics", stats)

func get_item_drop_statistics() -> Dictionary:
	update_item_drop_statistics()
	return get_state("item_drop_statistics", {})
