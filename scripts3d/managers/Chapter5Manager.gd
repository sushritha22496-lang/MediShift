extends Node3D

class_name Chapter5Manager

@onready var rama: RamaController = $Characters/Rama
var progression: GameProgression
var combat_engine: CombatEngine
var enemy_factory: EnemyFactory
var main_label: Label
var objective_label: Label
var monkeys_group: Node3D
var enemies_group: Node3D
var battle_started: bool = false
var ravana_defeated: bool = false

signal ravana_defeated_signal

func _ready() -> void:
	progression = GameProgression.new()
	add_child(progression)

	combat_engine = CombatEngine.new()
	add_child(combat_engine)

	enemy_factory = EnemyFactory.new()
	add_child(enemy_factory)

	monkeys_group = $Characters/Monkeys if has_node("Characters/Monkeys") else Node3D.new()
	enemies_group = $Enemies if has_node("Enemies") else Node3D.new()

	main_label = $HUD/MainLabel if has_node("HUD/MainLabel") else Label.new()
	objective_label = $HUD/ObjectiveLabel if has_node("HUD/ObjectiveLabel") else Label.new()

	progression.current_stage = GameProgression.Stage.BATTLE_RAVANA
	progression.advance_stage()

	_create_environment()
	_show_message("⚔️ CHAPTER 5: BATTLE OF LANKA\n\nRavana emerges from his fortress!\nPrepare for the final confrontation.\n\nPress SPACE to initiate battle!")

	if rama:
		rama.rama_called.connect(_on_rama_called)
		await get_tree().create_timer(2.0).timeout
		_spawn_enemies()

func _spawn_enemies() -> void:
	var ravana = enemy_factory.create_enemy_3d(EnemyFactory.EnemyType.RAVANA_BOSS, Vector3(0, 0, 50))
	if enemies_group:
		enemies_group.add_child(ravana)

	for i in range(5):
		var demon = enemy_factory.create_enemy_3d(EnemyFactory.EnemyType.LANKA_GUARD, Vector3(20 * cos(i * TAU / 5), 0, 50 + 15 * sin(i * TAU / 5)))
		if enemies_group:
			enemies_group.add_child(demon)

func _on_rama_called(intensity: float) -> void:
	if battle_started or ravana_defeated:
		return
	_start_battle()

func _start_battle() -> void:
	battle_started = true

	var rama_char = CombatEngine.Character.new()
	rama_char.name = "Rama"
	rama_char.max_health = 150
	rama_char.health = 150
	rama_char.attack = 20
	rama_char.defense = 10
	rama_char.speed = 12

	var hanuman_char = CombatEngine.Character.new()
	hanuman_char.name = "Hanuman"
	hanuman_char.max_health = 120
	hanuman_char.health = 120
	hanuman_char.attack = 18
	hanuman_char.defense = 8
	hanuman_char.speed = 14

	var ravana_char = CombatEngine.Character.new()
	ravana_char.name = "Ravana"
	ravana_char.max_health = 200
	ravana_char.health = 200
	ravana_char.attack = 25
	ravana_char.defense = 10
	ravana_char.speed = 10

	combat_engine.start_battle([rama_char, hanuman_char], [ravana_char])
	combat_engine.battle_ended.connect(_on_battle_ended)

	_show_message("⚔️ BATTLE STARTED!\n\nRama and Hanuman engage Ravana in fierce combat!\nThe fate of Sita hangs in the balance...")

func _on_battle_ended(victor: Array) -> void:
	if victor.size() > 0 and victor[0].name in ["Rama", "Hanuman"]:
		_victory()
	else:
		_defeat()

func _victory() -> void:
	ravana_defeated = true
	_show_message("🏆 VICTORY!\n\nRavana has fallen!\nThe demon king breathes his last...\n\n→ Advancing to CHAPTER 6: Rescue and Return")
	await get_tree().create_timer(3.0).timeout

	if progression:
		progression.advance_stage()

	SceneTransition.fade_to_scene(self, "res://scenes3d/chapters/chapter_6_rescue.tscn")

func _defeat() -> void:
	_show_message("💀 DEFEAT!\n\nRama's quest has ended...\nThe monkeys retreat in sorrow.")
	await get_tree().create_timer(3.0).timeout
	SceneTransition.fade_to_scene(self, "res://scenes3d/menu/main_menu.tscn")

func _show_message(message: String) -> void:
	if main_label:
		main_label.text = message
	if objective_label:
		var first_line = message.split("\n")[0]
		objective_label.text = "📍 " + first_line

func _create_environment() -> void:
	if has_node("Environment"):
		get_node("Environment").queue_free()
	var env = Node3D.new()
	env.name = "Environment"
	add_child(env)
	EnvironmentBuilder.create_fortress_environment(env)
	LightingSetup.setup_fortress_lighting(env)
