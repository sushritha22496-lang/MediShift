extends Node3D

class_name ItemSystem

enum ItemType { FRUIT, CLUE, RUNE }

@export var item_type: ItemType = ItemType.FRUIT
@export var item_name: String = "Mango"
@export var collection_radius: float = 2.0

@onready var model: MeshInstance3D = $Model
@onready var collision: Area3D = $CollectionArea

var collected: bool = false
var collector: Node3D = null

signal item_collected(item: ItemSystem, collector: Node3D)

func _ready() -> void:
	if collision:
		collision.area_entered.connect(_on_area_entered)
	add_to_group("items")

func _on_area_entered(area: Area3D) -> void:
	if not collected and area.is_in_group("player"):
		collect(area.get_parent())

func collect(collector_node: Node3D) -> void:
	if collected:
		return

	collected = true
	collector = collector_node
	item_collected.emit(self, collector)

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "global_position", collector.global_position + Vector3(0, 1, 0), 0.5)
	await tween.finished
	queue_free()

func get_item_display_name() -> String:
	return item_name

func get_item_type() -> ItemType:
	return item_type
