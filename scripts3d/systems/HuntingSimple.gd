extends Node

class_name HuntingSimple

class Game:
	var name: String
	var difficulty: String
	var meat_value: float
	var pelt_value: float
	var bones_count: int

	func _init(p_name: String, p_difficulty: String, p_meat: float, p_pelt: float, p_bones: int) -> void:
		name = p_name
		difficulty = p_difficulty
		meat_value = p_meat
		pelt_value = p_pelt
		bones_count = p_bones

var game_types: Array[Game] = []
var hunting_level: int = 1
var total_hunts: int = 0

signal animal_hunted(game: Game)
signal level_up(new_level: int)

func _ready() -> void:
	_initialize_game()

func _initialize_game() -> void:
	game_types.append(Game.new("Deer", "easy", 150, 100, 3))
	game_types.append(Game.new("Boar", "medium", 250, 200, 5))
	game_types.append(Game.new("Bear", "hard", 500, 400, 10))
	game_types.append(Game.new("Tiger", "very_hard", 800, 600, 15))

func hunt(location: Vector3) -> Game:
	var difficulty_roll = randf()
	var selected_game: Game = null

	if difficulty_roll < 0.4:
		selected_game = game_types[0]
	elif difficulty_roll < 0.7:
		selected_game = game_types[1]
	elif difficulty_roll < 0.9:
		selected_game = game_types[2]
	else:
		selected_game = game_types[3]

	total_hunts += 1

	if total_hunts >= hunting_level * 8:
		_level_up()

	animal_hunted.emit(selected_game)
	print("🏹 Hunted: %s (%s)" % [selected_game.name, selected_game.difficulty])
	return selected_game

func _level_up() -> void:
	hunting_level += 1
	level_up.emit(hunting_level)
	print("🏹 Hunting level: %d" % hunting_level)

func get_hunting_level() -> int:
	return hunting_level

func get_total_hunts() -> int:
	return total_hunts

func get_hunting_text() -> String:
	return "Hunting Level: %d | Hunts: %d" % [hunting_level, total_hunts]
