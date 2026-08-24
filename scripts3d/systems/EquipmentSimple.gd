extends Node

class_name EquipmentSimple

class Equipment:
	var id: String
	var name: String
	var slot: String
	var damage: float = 0.0
	var defense: float = 0.0
	var durability: float = 100.0
	var rarity: String = "common"

	func _init(p_id: String, p_name: String, p_slot: String) -> void:
		id = p_id
		name = p_name
		slot = p_slot

var equipped: Dictionary = {}
var available_slots: Array[String] = ["head", "body", "hands", "legs", "feet", "weapon", "shield"]

signal equipment_equipped(equipment: Equipment)
signal equipment_unequipped(slot: String)
signal durability_changed(equipment: Equipment)

func _ready() -> void:
	for slot in available_slots:
		equipped[slot] = null

func equip(equipment: Equipment) -> bool:
	if not equipment.slot in equipped:
		return false

	var old_equipment = equipped[equipment.slot]
	equipped[equipment.slot] = equipment
	equipment_equipped.emit(equipment)

	if old_equipment:
		equipment_unequipped.emit(equipment.slot)

	return true

func unequip(slot: String) -> bool:
	if slot in equipped and equipped[slot] != null:
		var equipment = equipped[slot]
		equipped[slot] = null
		equipment_unequipped.emit(slot)
		return true
	return false

func get_equipped(slot: String) -> Equipment:
	return equipped.get(slot, null)

func get_total_damage() -> float:
	var total = 0.0
	for slot in equipped:
		if equipped[slot] != null:
			total += equipped[slot].damage
	return total

func get_total_defense() -> float:
	var total = 0.0
	for slot in equipped:
		if equipped[slot] != null:
			total += equipped[slot].defense
	return total

func reduce_durability(slot: String, amount: float = 1.0) -> void:
	if slot in equipped and equipped[slot] != null:
		equipped[slot].durability -= amount
		durability_changed.emit(equipped[slot])

		if equipped[slot].durability <= 0:
			unequip(slot)

func repair(slot: String, amount: float = 50.0) -> void:
	if slot in equipped and equipped[slot] != null:
		equipped[slot].durability = minf(equipped[slot].durability + amount, 100.0)
		durability_changed.emit(equipped[slot])

func get_equipment_text() -> String:
	var text = "Equipment:\n"
	for slot in available_slots:
		if equipped[slot] != null:
			text += "%s: %s (Dur: %.0f%%)\n" % [slot, equipped[slot].name, equipped[slot].durability]
		else:
			text += "%s: Empty\n" % slot
	return text
