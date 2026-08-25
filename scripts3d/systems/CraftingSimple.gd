extends BaseSystemSimple

class_name CraftingSimple

class Recipe:
	var id: String
	var name: String
	var result_item: String
	var ingredients: Dictionary = {}
	var crafting_time: float = 1.0
	var difficulty: int
	var rarity: String
	var skill_requirement: int
	var mastery_bonus: float
	var quality_levels: int
	var prerequisites: Array[String]
	var critical_success_bonus: float
	func _init(p_id: String, p_name: String, p_result: String, p_difficulty: int = 1) -> void:
		id = p_id
		name = p_name
		result_item = p_result
		difficulty = p_difficulty
		rarity = "common" if p_difficulty < 3 else ("uncommon" if p_difficulty < 5 else "rare")
		skill_requirement = p_difficulty * 10
		mastery_bonus = 0.0
		quality_levels = 3
		prerequisites = []
		critical_success_bonus = 0.2

var recipes: Array[Recipe] = []

signal recipe_learned(recipe: Recipe)
signal crafting_started(recipe: Recipe)
signal crafting_completed(item: String, quality: int)
signal not_enough_materials(recipe: Recipe)
signal crafting_failed(recipe: Recipe)

func _ready() -> void:
	set_state("learned", [])
	set_state("crafting_skill", 0.0)
	set_state("recipe_mastery", {})
	set_state("crafting_history", [])
	set_state("learning_history", [])
	set_state("attempt_history", [])
	set_state("quality_tracking", {})
	set_state("skill_progression", [])
	set_state("crafting_statistics", {})
	set_state("ingredient_consumption", {})
	_initialize_recipes()

func _initialize_recipes() -> void:
	var recipe1 = Recipe.new("health_potion", "Health Potion", "Health Potion", 1)
	recipe1.ingredients = {"Herb": 2, "Water": 1}
	recipe1.crafting_time = 2.0
	recipes.append(recipe1)

	var recipe2 = Recipe.new("mana_potion", "Mana Potion", "Mana Potion", 2)
	recipe2.ingredients = {"Crystal": 1, "Blue Herb": 2}
	recipe2.crafting_time = 3.0
	recipe2.prerequisites = ["health_potion"]
	recipes.append(recipe2)

	var recipe3 = Recipe.new("iron_sword", "Iron Sword", "Iron Sword", 4)
	recipe3.ingredients = {"Iron Ore": 5, "Wood": 2}
	recipe3.crafting_time = 5.0
	recipe3.skill_requirement = 40
	recipes.append(recipe3)

	var recipe4 = Recipe.new("leather_armor", "Leather Armor", "Leather Armor", 3)
	recipe4.ingredients = {"Leather": 3, "Thread": 2}
	recipe4.crafting_time = 4.0
	recipe4.skill_requirement = 30
	recipes.append(recipe4)

func learn_recipe(recipe_id: String) -> bool:
	var learned = get_state("learned", [])
	for recipe in recipes:
		if recipe.id == recipe_id and not recipe in learned:
			if not _check_recipe_prerequisites(recipe):
				return false
			learned.append(recipe)
			_record_learning(recipe_id)
			recipe_learned.emit(recipe)
			emit_event("recipe_learned", recipe_id)
			return true
	return false

func _check_recipe_prerequisites(recipe: Recipe) -> bool:
	var learned = get_state("learned", [])
	for prereq_id in recipe.prerequisites:
		var found = false
		for learned_recipe in learned:
			if learned_recipe.id == prereq_id:
				found = true
				break
		if not found:
			return false
	return true

func craft(recipe_id: String, inventory: InventorySimple) -> bool:
	var learned = get_state("learned", [])
	var crafting_skill = get_state("crafting_skill", 0.0)
	for recipe in learned:
		if recipe.id == recipe_id:
			if not _has_materials(recipe, inventory):
				not_enough_materials.emit(recipe)
				return false
			if crafting_skill < recipe.skill_requirement:
				return false
			var success_rate = _calculate_success_rate(recipe, crafting_skill)
			for ingredient in recipe.ingredients:
				inventory.remove_item(ingredient, recipe.ingredients[ingredient])
				_record_ingredient_consumption(ingredient, recipe.ingredients[ingredient])
			crafting_started.emit(recipe)
			await get_tree().create_timer(recipe.crafting_time).timeout
			if randf() < success_rate:
				var quality = _determine_quality(recipe, crafting_skill)
				inventory.add_item(recipe.result_item, 1)
				_record_attempt(recipe_id, true, quality)
				_record_quality(recipe_id, quality)
				_record_skill_progression(crafting_skill + (recipe.difficulty * 0.5))
				crafting_completed.emit(recipe.result_item, quality)
				_increase_mastery(recipe_id)
				_increase_crafting_skill(recipe.difficulty)
				emit_event("crafted", {"recipe": recipe_id, "quality": quality})
				return true
			else:
				_record_attempt(recipe_id, false, 0)
				crafting_failed.emit(recipe)
				emit_event("crafting_failed", recipe_id)
				return false
	return false

func _calculate_success_rate(recipe: Recipe, skill: float) -> float:
	var base_rate = 0.5 + ((skill - recipe.skill_requirement) * 0.01)
	var mastery = get_state("recipe_mastery", {})
	var mastery_bonus = mastery.get(recipe.id, 0.0) * 0.02
	return clamp(base_rate + mastery_bonus, 0.1, 0.95)

func _determine_quality(recipe: Recipe, skill: float) -> int:
	var base_quality = 1
	if randf() < 0.1 + ((skill - recipe.skill_requirement) * 0.005):
		base_quality = 3
	elif randf() < 0.3 + ((skill - recipe.skill_requirement) * 0.01):
		base_quality = 2
	return base_quality

func _increase_mastery(recipe_id: String) -> void:
	var mastery = get_state("recipe_mastery", {})
	mastery[recipe_id] = mastery.get(recipe_id, 0.0) + 1.0
	set_state("recipe_mastery", mastery)

func _increase_crafting_skill(recipe_difficulty: int) -> void:
	var skill = get_state("crafting_skill", 0.0)
	skill += recipe_difficulty * 0.5
	set_state("crafting_skill", skill)
	emit_event("crafting_skill_increased", skill)

func _has_materials(recipe: Recipe, inventory: InventorySimple) -> bool:
	for ingredient in recipe.ingredients:
		if inventory.get_item_count(ingredient) < recipe.ingredients[ingredient]:
			return false
	return true

func get_learned_recipes() -> Array:
	return get_state("learned", [])

func get_recipe(recipe_id: String) -> Recipe:
	for recipe in recipes:
		if recipe.id == recipe_id:
			return recipe
	return null

func get_recipes_text() -> String:
	var learned = get_state("learned", [])
	var skill = get_state("crafting_skill", 0.0)
	var text = "Recipes [%d] | Skill: %.0f\n" % [learned.size(), skill]
	for recipe in learned:
		var mastery = get_state("recipe_mastery", {})
		var mastery_level = int(mastery.get(recipe.id, 0.0))
		text += "%s (Mastery: %d)\n" % [recipe.name, mastery_level]
	return text

func get_recipe_mastery(recipe_id: String) -> float:
	var mastery = get_state("recipe_mastery", {})
	return mastery.get(recipe_id, 0.0)

func _record_learning(recipe_id: String) -> void:
	var history = get_state("learning_history", [])
	history.append({"recipe": recipe_id, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("learning_history", history)

func _record_attempt(recipe_id: String, success: bool, quality: int) -> void:
	var history = get_state("attempt_history", [])
	history.append({"recipe": recipe_id, "success": success, "quality": quality, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("attempt_history", history)

func _record_quality(recipe_id: String, quality: int) -> void:
	var tracking = get_state("quality_tracking", {})
	if recipe_id not in tracking:
		tracking[recipe_id] = {"high": 0, "medium": 0, "low": 0}
	if quality == 3:
		tracking[recipe_id]["high"] += 1
	elif quality == 2:
		tracking[recipe_id]["medium"] += 1
	else:
		tracking[recipe_id]["low"] += 1
	set_state("quality_tracking", tracking)

func _record_ingredient_consumption(ingredient: String, amount: int) -> void:
	var consumption = get_state("ingredient_consumption", {})
	consumption[ingredient] = consumption.get(ingredient, 0) + amount
	set_state("ingredient_consumption", consumption)

func _record_skill_progression(skill_value: float) -> void:
	var progression = get_state("skill_progression", [])
	progression.append({"skill": skill_value, "time": Time.get_ticks_msec()})
	if progression.size() > 50:
		progression.pop_front()
	set_state("skill_progression", progression)

func update_crafting_statistics() -> void:
	var stats = get_state("crafting_statistics", {})
	var attempts = get_state("attempt_history", [])
	var successes = 0
	for attempt in attempts:
		if attempt.get("success", false):
			successes += 1
	stats["recipes_learned"] = get_state("learning_history", []).size()
	stats["total_attempts"] = attempts.size()
	stats["successful_crafts"] = successes
	stats["success_rate"] = float(successes) / float(attempts.size()) if attempts.size() > 0 else 0.0
	stats["current_skill"] = get_state("crafting_skill", 0.0)
	stats["total_mastery"] = get_state("recipe_mastery", {}).size()
	stats["recipes_available"] = recipes.size()
	stats["unique_ingredients_used"] = get_state("ingredient_consumption", {}).size()
	set_state("crafting_statistics", stats)

func get_crafting_statistics() -> Dictionary:
	update_crafting_statistics()
	return get_state("crafting_statistics", {})

func get_crafting_skill() -> float:
	return get_state("crafting_skill", 0.0)
