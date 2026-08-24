extends BaseSystemSimple

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

signal animal_hunted(game: Game)
signal level_up(new_level: int)

func _ready() -> void:
	set_state("level", 1)
	set_state("hunts", 0)
	_initialize_game()

func _initialize_game() -> void:
	game_types.append(Game.new("Deer", "easy", 150, 100, 3))
	game_types.append(Game.new("Boar", "medium", 250, 200, 5))
	game_types.append(Game.new("Bear", "hard", 500, 400, 10))
	game_types.append(Game.new("Tiger", "very_hard", 800, 600, 15))

func hunt(location: Vector3) -> Game:
	var difficulty_roll = randf()
	var idx = 0 if difficulty_roll < 0.4 else (1 if difficulty_roll < 0.7 else (2 if difficulty_roll < 0.9 else 3))
	var selected_game = game_types[idx]
	var hunts = get_state("hunts", 0) + 1
	set_state("hunts", hunts)
	if hunts >= get_state("level", 1) * 8:
		_level_up()
	animal_hunted.emit(selected_game)
	emit_event("hunted", selected_game.name)
	return selected_game

func _level_up() -> void:
	var level = get_state("level", 1) + 1
	set_state("level", level)
	level_up.emit(level)
	emit_event("level_up", level)

func get_hunting_level() -> int:
	return get_state("level", 1)

func get_total_hunts() -> int:
	return get_state("hunts", 0)

func get_hunting_text() -> String:
	var level = get_state("level", 1)
	var hunts = get_state("hunts", 0)
	return "Hunting Level: %d | Hunts: %d" % [level, hunts]
