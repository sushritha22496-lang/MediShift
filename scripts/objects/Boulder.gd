extends RigidBody2D

# ─── Boulder — pick up, carry, throw into the ocean (Ram Setu mini-game) ──────

const PICKUP_RANGE := 90.0
const CARRY_OFFSET := Vector2(40, -60)
const THROW_FORCE := 600.0

var is_held: bool = false
var holder: CharacterBody2D = null

signal placed_in_ocean()

@onready var pickup_area: Area2D = $PickupArea
@onready var ocean_detector: Area2D = $OceanDetector

func _ready() -> void:
	add_to_group("boulders")
	ocean_detector.area_entered.connect(_on_ocean_entered)

func _physics_process(_delta: float) -> void:
	if is_held and holder:
		freeze = true
		global_position = holder.global_position + CARRY_OFFSET * Vector2(1.0 if holder.facing_right else -1.0, 1.0)
		_check_release_input()
	else:
		_check_pickup_input()

func _check_pickup_input() -> void:
	if not Input.is_action_just_pressed("interact"):
		return
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return
	if global_position.distance_to(player.global_position) <= PICKUP_RANGE and not _any_boulder_held():
		is_held = true
		holder = player
		freeze = true

func _check_release_input() -> void:
	if Input.is_action_just_pressed("attack"):
		_throw()

func _throw() -> void:
	if not holder:
		return
	var dir := 1.0 if holder.facing_right else -1.0
	is_held = false
	freeze = false
	linear_velocity = Vector2(dir * THROW_FORCE, -300.0)
	AudioManager.play_sfx("gada_heavy")
	holder = null

func _any_boulder_held() -> bool:
	for b in get_tree().get_nodes_in_group("boulders"):
		if b != self and b.is_held:
			return true
	return false

func _on_ocean_entered(_area: Area2D) -> void:
	placed_in_ocean.emit()
	queue_free()
