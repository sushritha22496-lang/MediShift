extends Node3D

class_name Chapter2Manager

var progression: GameProgression
var quest_system: SimpleQuestSystem
var monkey_spawner: MonkeySpawner
var enemy_factory: EnemyFactory

var rama: RamaController
var hanuman: HanumanAI
var gathered_monkeys: int = 0
var required_monkeys: int = 5

signal chapter_progressed

func _ready() -> void:
	progression = get_node_or_null("/root/GameManager")
	rama = $Characters/Rama
	hanuman = $Characters/Hanuman

	monkey_spawner = MonkeySpawner.new()
	add_child(monkey_spawner)

	enemy_factory = EnemyFactory.new()
	add_child(enemy_factory)

	quest_system = SimpleQuestSystem.new()
	add_child(quest_system)

	_create_environment()
	_setup_chapter_2()

func _setup_chapter_2() -> void:
	_show_message("🌲 CHAPTER 2: GATHERING ALLIES\n\nHanuman leads you to recruit monkey generals...")
	await get_tree().create_timer(3.0).timeout

	_show_message("We must gather warriors. Travel north to the Monkey Council...")

	quest_system.start_quest("gather_monkeys")

func recruit_monkey_general(name: String) -> void:
	gathered_monkeys += 1
	_show_message("✅ %s joins the quest! (%d/%d)" % [name, gathered_monkeys, required_monkeys])

	if gathered_monkeys >= required_monkeys:
		_chapter_complete()

func _chapter_complete() -> void:
	_show_message("✅ MONKEY ARMY ASSEMBLED!\n\nWe march toward Lanka!")
	quest_system.complete_quest("gather_monkeys")

	if progression:
		progression.monkeys_gathered = required_monkeys
		progression.advance_stage()

	await get_tree().create_timer(3.0).timeout
	chapter_progressed.emit()

func spawn_forest_encounter() -> void:
	var demon_positions = [
		rama.global_position + Vector3(10, 0, 0),
		rama.global_position + Vector3(15, 0, 5),
		rama.global_position + Vector3(12, 0, -8)
	]

	await enemy_factory.spawn_forest_ambush(rama.global_position, 3)
	_show_message("⚠️ Demons ambush! Defeat them to advance!")

func _show_message(text: String) -> void:
	var hud = get_node_or_null("/root/HUD")
	if hud and hud.has_method("show_message"):
		hud.show_message(text)
	else:
		print(text)

func _create_environment() -> void:
	if has_node("Environment"):
		get_node("Environment").queue_free()
	var env = Node3D.new()
	env.name = "Environment"
	add_child(env)
	EnvironmentBuilder.create_forest_environment(env, "sparse")
