extends BaseSystemSimple

class_name CraftingSimple

class Recipe:
	var id: String
	var name: String
	var result_item: String
	var ingredients: Dictionary = {}
	var crafting_time: float = 1.0
	func _init(p_id: String, p_name: String, p_result: String) -> void:
		id = p_id
		name = p_name
		result_item = p_result

var recipes: Array[Recipe] = []

signal recipe_learned(recipe: Recipe)
signal crafting_started(recipe: Recipe)
signal crafting_completed(item: String)
signal not_enough_materials(recipe: Recipe)

func _ready() -> void:
	set_state("learned", [])
	_initialize_recipes()

func _initialize_recipes() -> void:
	var recipe1 = Recipe.new("health_potion", "Health Potion", "Health Potion")
	recipe1.ingredients = {"Herb": 2, "Water": 1}
	recipe1.crafting_time = 2.0
	recipes.append(recipe1)

	var recipe2 = Recipe.new("mana_potion", "Mana Potion", "Mana Potion")
	recipe2.ingredients = {"Crystal": 1, "Blue Herb": 2}
	recipe2.crafting_time = 3.0
	recipes.append(recipe2)

	var recipe3 = Recipe.new("iron_sword", "Iron Sword", "Iron Sword")
	recipe3.ingredients = {"Iron Ore": 5, "Wood": 2}
	recipe3.crafting_time = 5.0
	recipes.append(recipe3)

	var recipe4 = Recipe.new("leather_armor", "Leather Armor", "Leather Armor")
	recipe4.ingredients = {"Leather": 3, "Thread": 2}
	recipe4.crafting_time = 4.0
	recipes.append(recipe4)

func learn_recipe(recipe_id: String) -> bool:
	var learned = get_state("learned", [])
	for recipe in recipes:
		if recipe.id == recipe_id and not recipe in learned:
			learned.append(recipe)
			recipe_learned.emit(recipe)
			emit_event("recipe_learned", recipe_id)
			return true
	return false

func craft(recipe_id: String, inventory: InventorySimple) -> bool:
	var learned = get_state("learned", [])
	for recipe in learned:
		if recipe.id == recipe_id:
			if not _has_materials(recipe, inventory):
				not_enough_materials.emit(recipe)
				return false
			for ingredient in recipe.ingredients:
				inventory.remove_item(ingredient, recipe.ingredients[ingredient])
			crafting_started.emit(recipe)
			await get_tree().create_timer(recipe.crafting_time).timeout
			inventory.add_item(recipe.result_item, 1)
			crafting_completed.emit(recipe.result_item)
			emit_event("crafted", recipe_id)
			return true
	return false

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
	var text = "Recipes [%d]:\n" % learned.size()
	for recipe in learned:
		text += "%s\n" % recipe.name
	return text
