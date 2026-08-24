extends Node3D

class_name CollectibleSimple

@export var item_name: String = "Mango"
@export var item_quantity: int = 1
@export var pickup_range: float = 3.0

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var area: Area3D = $Area3D

signal item_collected(item_name: String, quantity: int)

func _ready() -> void:
	if area:
		area.body_entered.connect(_on_area_entered)

func _on_area_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		var distance = global_position.distance_to(body.global_position)
		if distance < pickup_range:
			collect(body)

func collect(collector: Node3D) -> void:
	if collector.has_method("add_to_inventory"):
		collector.add_to_inventory(item_name, item_quantity)
	item_collected.emit(item_name, item_quantity)
	queue_free()

func set_item(name: String, qty: int = 1) -> void:
	item_name = name
	item_quantity = qty
