extends BaseSystemSimple

class_name AlchemySimple

class Potion:
	var id: String
	var name: String
	var effect: String
	var ingredients: Dictionary = {}
	var brewing_time: float = 1.0
	var difficulty: int
	var reagent_quality: float = 1.0
	var potency: int = 1
	var max_potency: int = 5
	var success_rate: float = 0.8
	var side_effects: Array[String] = []
	var prerequisites: Array[String] = []
	var mastery_bonus: float = 0.0
	func _init(p_id: String, p_name: String, p_effect: String, p_difficulty: int = 1) -> void:
		id = p_id
		name = p_name
		effect = p_effect
		difficulty = p_difficulty
		success_rate = 0.8 - (p_difficulty * 0.1)

var known_potions: Array[Potion] = []

signal potion_formula_learned(potion: Potion)
signal brewing_started(potion: Potion)
signal potion_created(potion: Potion)
signal brewing_failed

func _ready() -> void:
	set_state("learned", [])
	set_state("alchemy_skill", 0.0)
	set_state("potion_mastery", {})
	set_state("brewing_history", [])
	set_state("contamination", 0)
	set_state("ingredient_quality", {})
	set_state("potion_batches", [])
	set_state("catalyst_effects", {})
	set_state("experiments", [])
	set_state("recipe_discoveries", [])
	set_state("lab_upgrades", [])
	set_state("breakthrough_count", 0)
	_initialize_potions()

func _initialize_potions() -> void:
	var p1 = Potion.new("health_potion", "Health Potion", "Restore 50 HP", 1)
	p1.ingredients = {"Red Herb": 2, "Water": 1}
	p1.brewing_time = 2.0
	p1.side_effects = ["minor_bitterness"]

	var p2 = Potion.new("mana_potion", "Mana Potion", "Restore 30 Mana", 2)
	p2.ingredients = {"Blue Crystal": 1, "Essence": 2}
	p2.brewing_time = 3.0
	p2.prerequisites = ["health_potion"]
	p2.side_effects = ["cold_sensation"]

	var p3 = Potion.new("strength_potion", "Strength Potion", "Boost Attack +20", 3)
	p3.ingredients = {"Tiger Fang": 1, "Herb": 3}
	p3.brewing_time = 4.0
	p3.prerequisites = ["health_potion"]
	p3.side_effects = ["temporary_rage", "increased_appetite"]

	known_potions = [p1, p2, p3]

func learn_formula(potion_id: String) -> bool:
	var learned = get_state("learned", [])
	for potion in known_potions:
		if potion.id == potion_id and potion not in learned:
			if not _check_formula_prerequisites(potion):
				return false
			learned.append(potion)
			potion_formula_learned.emit(potion)
			emit_event("learned", potion_id)
			return true
	return false

func _check_formula_prerequisites(potion: Potion) -> bool:
	var learned = get_state("learned", [])
	for prereq_id in potion.prerequisites:
		var found = false
		for p in learned:
			if p.id == prereq_id:
				found = true
				break
		if not found:
			return false
	return true

func brew_potion(potion_id: String, inventory: InventorySimple) -> bool:
	var learned = get_state("learned", [])
	for potion in learned:
		if potion.id == potion_id:
			if not _has_ingredients(potion, inventory):
				brewing_failed.emit()
				return false
			var skill = get_state("alchemy_skill", 0.0)
			var success_rate = _calculate_success_rate(potion, skill)
			for ingredient in potion.ingredients:
				inventory.remove_item(ingredient, potion.ingredients[ingredient])
			brewing_started.emit(potion)
			await get_tree().create_timer(potion.brewing_time).timeout
			if randf() < success_rate:
				var potency = _determine_potency(potion, skill)
				var item_name = "%s (Lvl %d)" % [potion.name, potency]
				inventory.add_item(item_name, 1)
				_increase_mastery(potion_id, skill)
				_increase_alchemy_skill(potion.difficulty)
				potion_created.emit(potion)
				emit_event("brewed", {"potion": potion_id, "potency": potency})
				return true
			else:
				_increase_contamination()
				brewing_failed.emit()
				emit_event("brewing_failed", potion_id)
				return false
	return false

func _calculate_success_rate(potion: Potion, skill: float) -> float:
	var base_rate = potion.success_rate
	var skill_bonus = (skill / (potion.difficulty * 10.0)) * 0.3
	var contamination_penalty = (get_state("contamination", 0) * 0.02)
	return clamp(base_rate + skill_bonus - contamination_penalty, 0.1, 0.95)

func _determine_potency(potion: Potion, skill: float) -> int:
	if randf() < 0.1 + ((skill - (potion.difficulty * 10.0)) * 0.005):
		return 5
	elif randf() < 0.25 + ((skill - (potion.difficulty * 10.0)) * 0.01):
		return 4
	elif randf() < 0.5:
		return 3
	elif randf() < 0.75:
		return 2
	return 1

func _increase_mastery(potion_id: String, skill: float) -> void:
	var mastery = get_state("potion_mastery", {})
	mastery[potion_id] = mastery.get(potion_id, 0.0) + 1.0
	set_state("potion_mastery", mastery)

func _increase_alchemy_skill(potion_difficulty: int) -> void:
	var skill = get_state("alchemy_skill", 0.0)
	skill += potion_difficulty * 0.5
	set_state("alchemy_skill", skill)
	emit_event("alchemy_skill_increased", skill)

func _increase_contamination() -> void:
	var contamination = get_state("contamination", 0) + 1
	set_state("contamination", contamination)
	if contamination >= 10:
		set_state("contamination", 0)
		emit_event("lab_cleaned", {})

func _has_ingredients(potion: Potion, inventory: InventorySimple) -> bool:
	for ingredient in potion.ingredients:
		if inventory.get_item_count(ingredient) < potion.ingredients[ingredient]:
			return false
	return true

func get_known_potions() -> Array:
	return get_state("learned", [])

func get_potion_mastery(potion_id: String) -> float:
	var mastery = get_state("potion_mastery", {})
	return mastery.get(potion_id, 0.0)

func get_alchemy_skill() -> float:
	return get_state("alchemy_skill", 0.0)

func get_contamination_level() -> int:
	return get_state("contamination", 0)

func get_potions_text() -> String:
	var learned = get_state("learned", [])
	var skill = get_state("alchemy_skill", 0.0)
	var contamination = get_state("contamination", 0)
	var text = "Potions [%d] | Skill: %.0f | Contamination: %d\n" % [learned.size(), skill, contamination]
	for potion in learned:
		var mastery = get_state("potion_mastery", {})
		text += "%s (Mastery: %d)\n" % [potion.name, int(mastery.get(potion.id, 0.0))]
	return text

func set_ingredient_quality(ingredient: String, quality: float) -> void:
	var qualities = get_state("ingredient_quality", {})
	qualities[ingredient] = clampf(quality, 0.0, 1.0)
	set_state("ingredient_quality", qualities)
	emit_event("ingredient_quality_set", ingredient)

func get_ingredient_quality(ingredient: String) -> float:
	var qualities = get_state("ingredient_quality", {})
	return qualities.get(ingredient, 0.7)

func record_potion_batch(potion_id: String, batch_size: int, quality: float) -> void:
	var batches = get_state("potion_batches", [])
	batches.append({"potion": potion_id, "size": batch_size, "quality": quality, "time": Time.get_ticks_msec()})
	if batches.size() > 50:
		batches.pop_front()
	set_state("potion_batches", batches)

func apply_catalyst_effect(catalyst: String, effect: String) -> void:
	var effects = get_state("catalyst_effects", {})
	if catalyst not in effects:
		effects[catalyst] = []
	effects[catalyst].append(effect)
	set_state("catalyst_effects", effects)
	emit_event("catalyst_applied", catalyst)

func record_experiment(experiment_data: Dictionary) -> void:
	var experiments = get_state("experiments", [])
	experiments.append({"data": experiment_data, "time": Time.get_ticks_msec()})
	if experiments.size() > 40:
		experiments.pop_front()
	set_state("experiments", experiments)
	emit_event("experiment_recorded", experiment_data)

func discover_recipe(recipe_name: String, ingredients: Array) -> void:
	var discoveries = get_state("recipe_discoveries", [])
	discoveries.append({"name": recipe_name, "ingredients": ingredients, "time": Time.get_ticks_msec()})
	set_state("recipe_discoveries", discoveries)
	emit_event("recipe_discovered", recipe_name)

func add_lab_upgrade(upgrade: String) -> void:
	var upgrades = get_state("lab_upgrades", [])
	upgrades.append(upgrade)
	set_state("lab_upgrades", upgrades)
	emit_event("lab_upgraded", upgrade)

func record_breakthrough() -> void:
	var count = get_state("breakthrough_count", 0)
	set_state("breakthrough_count", count + 1)
	emit_event("breakthrough_achieved", count + 1)

func get_lab_upgrades() -> Array:
	return get_state("lab_upgrades", [])

func has_lab_upgrade(upgrade: String) -> bool:
	return upgrade in get_lab_upgrades()

func get_total_potions_brewed() -> int:
	var batches = get_state("potion_batches", [])
	var total = 0
	for batch in batches:
		total += batch["size"]
	return total

func get_experiment_count() -> int:
	return get_state("experiments", []).size()

func get_breakthrough_count() -> int:
	return get_state("breakthrough_count", 0)
