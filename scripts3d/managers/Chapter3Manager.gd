extends Node3D

class_name Chapter3Manager

@onready var rama: RamaController = $Characters/Rama
var progression: GameProgression
var location_manager: LocationManager
var main_label: Label
var objective_label: Label
var monkeys_group: Node3D
var waypoints: Array[Vector3]
var current_waypoint: int = 0
var destination_reached: bool = false

func _ready() -> void:
	progression = GameProgression.new()
	add_child(progression)

	location_manager = LocationManager.new()
	add_child(location_manager)

	monkeys_group = $Characters/Monkeys if has_node("Characters/Monkeys") else Node3D.new()
	if not has_node("Characters/Monkeys"):
		$Characters.add_child(monkeys_group)
		monkeys_group.name = "Monkeys"

	main_label = $HUD/MainLabel if has_node("HUD/MainLabel") else Label.new()
	objective_label = $HUD/ObjectiveLabel if has_node("HUD/ObjectiveLabel") else Label.new()

	progression.current_stage = GameProgression.Stage.TRAVEL_TO_COAST
	progression.advance_stage()

	_create_environment()
	_initialize_waypoints()
	_show_message("🌊 CHAPTER 3: JOURNEY TO THE COAST\n\nThe army of monkeys marches toward the ocean.\nNavigate through forests and rivers to reach Lanka.\n\nPress SPACE to call for Hanuman's guidance!")

	if rama:
		rama.rama_called.connect(_on_rama_called)

func _initialize_waypoints() -> void:
	waypoints = [
		rama.global_position + Vector3(0, 0, 50),
		rama.global_position + Vector3(50, 0, 100),
		rama.global_position + Vector3(100, 0, 150),
		rama.global_position + Vector3(150, 0, 200),
		rama.global_position + Vector3(200, 0, 250)
	]

func _physics_process(delta: float) -> void:
	if rama and not destination_reached:
		var dist_to_waypoint = rama.global_position.distance_to(waypoints[current_waypoint])

		if dist_to_waypoint < 15.0:
			current_waypoint += 1
			if current_waypoint >= waypoints.size():
				_reach_coast()
			else:
				_show_message("✅ Waypoint reached! Continue toward the coast...")

func _on_rama_called(intensity: float) -> void:
	if destination_reached:
		return
	_show_message("📢 Rama: Onward to Lanka!\n\nHanuman appears and points toward the ocean shore ahead.\nThe journey continues...")

func _reach_coast() -> void:
	destination_reached = true
	_show_message("🌊 COAST REACHED!\n\nThe vast ocean stretches before us.\nHanuman must build a bridge across to Lanka.\n\n→ Advancing to CHAPTER 4: Ocean Crossing")
	await get_tree().create_timer(3.0).timeout

	if progression:
		progression.advance_stage()

	SceneTransition.fade_to_scene(self, "res://scenes3d/chapters/chapter_4_ocean.tscn")

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
	EnvironmentBuilder.create_coast_environment(env)
	LightingSetup.setup_coast_lighting(env)
