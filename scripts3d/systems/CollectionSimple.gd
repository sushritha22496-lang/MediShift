extends BaseSystemSimple

class_name CollectionSimple

class Collectible:
	var id: String
	var name: String
	var category: String
	var description: String
	var rarity: String
	var collected: bool
	func _init(p_id: String, p_name: String, p_cat: String, p_desc: String, p_rarity: String = "common") -> void:
		id = p_id
		name = p_name
		category = p_cat
		description = p_desc
		rarity = p_rarity
		collected = false

var collectibles: Array[Collectible] = []

signal collectible_found(collectible: Collectible)
signal collection_completed(category: String)

func _ready() -> void:
	set_state("collected_items", [])
	_initialize_collectibles()

func _initialize_collectibles() -> void:
	var categories = ["flowers", "stones", "artifacts", "relics", "crystals"]
	for cat in categories:
		for i in range(5):
			var c = Collectible.new("%s_%d" % [cat, i], "%s Collectible %d" % [cat.capitalize(), i+1], cat, "A rare %s" % cat, ["common", "uncommon", "rare"][randi() % 3])
			collectibles.append(c)

func find_collectible(collectible_id: String) -> bool:
	var c = _get_collectible(collectible_id)
	if c and not c.collected:
		c.collected = true
		var collected = get_state("collected_items", [])
		collected.append(collectible_id)
		set_state("collected_items", collected)
		collectible_found.emit(c)
		emit_event("collectible_found", collectible_id)

		if _is_category_complete(c.category):
			collection_completed.emit(c.category)
			emit_event("collection_completed", c.category)
		return true
	return false

func get_collectible(collectible_id: String) -> Collectible:
	return _get_collectible(collectible_id)

func get_collected_in_category(category: String) -> Array[Collectible]:
	var collected_ids = get_state("collected_items", [])
	var result: Array[Collectible] = []
	for c in collectibles:
		if c.id in collected_ids and c.category == category:
			result.append(c)
	return result

func get_category_progress(category: String) -> float:
	var total = collectibles.filter(func(c): return c.category == category).size()
	var collected = get_collected_in_category(category).size()
	return float(collected) / float(total) * 100.0 if total > 0 else 0.0

func get_total_progress() -> float:
	var collected_ids = get_state("collected_items", [])
	return (float(collected_ids.size()) / float(collectibles.size())) * 100.0 if collectibles.size() > 0 else 0.0

func get_collection_text() -> String:
	var text = "Collection: %.0f%% complete\n" % get_total_progress()
	var categories = {}
	for c in collectibles:
		if c.category not in categories:
			categories[c.category] = 0
		if c.collected:
			categories[c.category] += 1
	for cat in categories.keys():
		text += "%s: %d\n" % [cat.capitalize(), categories[cat]]
	return text

func _get_collectible(collectible_id: String) -> Collectible:
	for c in collectibles:
		if c.id == collectible_id:
			return c
	return null

func _is_category_complete(category: String) -> bool:
	var all_in_cat = collectibles.filter(func(c): return c.category == category)
	var collected = get_collected_in_category(category)
	return collected.size() == all_in_cat.size()
