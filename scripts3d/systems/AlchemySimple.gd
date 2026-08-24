extends BaseSystemSimple

class_name AlchemySimple

class Potion:
	var id: String
	var name: String
	var effect: String
	var ingredients: Dictionary = {}
	var brewing_time: float = 1.0
	func _init(p_id: String, p_name: String, p_effect: String) -> void:
		id = p_id
		name = p_name
		effect = p_effect

var known_potions: Array[Potion] = []

signal potion_formula_learned(potion: Potion)
signal brewing_started(potion: Potion)
signal potion_created(potion: Potion)
signal brewing_failed

func _ready() -> void:
	set_state("learned", [])
	_initialize_potions()

func _initialize_potions() -> void:
	var p1 = Potion.new("health_potion", "Health Potion", "Restore 50 HP")
	p1.ingredients = {"Red Herb": 2, "Water": 1}
	p1.brewing_time = 2.0

	var p2 = Potion.new("mana_potion", "Mana Potion", "Restore 30 Mana")
	p2.ingredients = {"Blue Crystal": 1, "Essence": 2}
	p2.brewing_time = 3.0

	var p3 = Potion.new("strength_potion", "Strength Potion", "Boost Attack +20")
	p3.ingredients = {"Tiger Fang": 1, "Herb": 3}
	p3.brewing_time = 4.0

	known_potions = [p1, p2, p3]

func learn_formula(potion_id: String) -> bool:
	var learned = get_state("learned", [])
	for potion in known_potions:
		if potion.id == potion_id:
			learned.append(potion)
			potion_formula_learned.emit(potion)
			emit_event("learned", potion_id)
			return true
	return false

func brew_potion(potion_id: String, inventory: InventorySimple) -> bool:
	var learned = get_state("learned", [])
	for potion in learned:
		if potion.id == potion_id:
			if not _has_ingredients(potion, inventory):
				brewing_failed.emit()
				return false
			for ingredient in potion.ingredients:
				inventory.remove_item(ingredient, potion.ingredients[ingredient])
			brewing_started.emit(potion)
			await get_tree().create_timer(potion.brewing_time).timeout
			inventory.add_item(potion.name, 1)
			potion_created.emit(potion)
			emit_event("brewed", potion_id)
			return true
	return false

func _has_ingredients(potion: Potion, inventory: InventorySimple) -> bool:
	for ingredient in potion.ingredients:
		if inventory.get_item_count(ingredient) < potion.ingredients[ingredient]:
			return false
	return true

func get_known_potions() -> Array:
	return get_state("learned", [])

func get_potions_text() -> String:
	var learned = get_state("learned", [])
	var text = "Known Potions [%d]:\n" % learned.size()
	for potion in learned:
		text += "%s (%s)\n" % [potion.name, potion.effect]
	return text
