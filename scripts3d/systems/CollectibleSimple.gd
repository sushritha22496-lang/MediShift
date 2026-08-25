extends Node3D

class_name CollectibleSimple

@export var item_name: String = "Mango"
@export var item_quantity: int = 1
@export var pickup_range: float = 3.0
@export var rarity: String = "common"
@export var despawn_time_ms: int = 300000

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var area: Area3D = $Area3D

signal item_collected(item_name: String, quantity: int)
signal item_despawned
signal rarity_collected(rarity: String)

var spawn_time: int = 0
var collection_effects: Dictionary = {}
var animation_data: Dictionary = {}
var particle_effect_name: String = ""
var collection_attempt_history: Array = []

func _ready() -> void:
	spawn_time = Time.get_ticks_msec()
	if area:
		area.body_entered.connect(_on_area_entered)
	if despawn_time_ms > 0:
		await get_tree().create_timer(despawn_time_ms / 1000.0).timeout
		despawn()

func _on_area_entered(body: Node3D) -> void:
	if body.is_in_group("player") and global_position.distance_to(body.global_position) < pickup_range:
		collect(body)

func _record_collection_attempt(collector_name: String, success: bool) -> void:
	collection_attempt_history.append({"collector": collector_name, "success": success, "lifetime": get_lifetime_ms(), "time": Time.get_ticks_msec()})
	if collection_attempt_history.size() > 50:
		collection_attempt_history.pop_front()

func collect(collector: Node3D) -> void:
	if collector.has_method("add_to_inventory"):
		collector.add_to_inventory(item_name, item_quantity)
	_record_collection_attempt(collector.name, true)
	rarity_collected.emit(rarity)
	item_collected.emit(item_name, item_quantity)
	queue_free()

func set_item(name: String, qty: int = 1) -> void:
	item_name = name
	item_quantity = qty

func set_rarity(new_rarity: String) -> void:
	rarity = new_rarity

func get_rarity() -> String:
	return rarity

func set_particle_effect(effect_name: String) -> void:
	particle_effect_name = effect_name

func add_collection_effect(effect_name: String, data: Dictionary) -> void:
	collection_effects[effect_name] = data

func set_animation_data(anim_name: String, duration: float) -> void:
	animation_data[anim_name] = duration

func get_spawn_time() -> int:
	return spawn_time

func get_lifetime_ms() -> int:
	return Time.get_ticks_msec() - spawn_time

func despawn() -> void:
	item_despawned.emit()
	queue_free()

func trigger_collection_effects() -> void:
	for effect in collection_effects:
		emit_signal("item_collected", item_name, item_quantity)
	rarity_collected.emit(rarity)

func get_collectible_statistics() -> Dictionary:
	return {
		"item_name": item_name,
		"rarity": rarity,
		"lifetime_ms": get_lifetime_ms(),
		"collection_attempts": collection_attempt_history.size(),
		"effects_registered": collection_effects.size(),
		"animations_registered": animation_data.size()
	}
