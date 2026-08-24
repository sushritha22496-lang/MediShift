extends BaseSystemSimple

class_name WeaponSimple

class Weapon:
	var id: String
	var name: String
	var type: String
	var damage: float
	var attack_speed: float
	var weight: float
	var rarity: String
	func _init(p_id: String, p_name: String, p_type: String, p_damage: float, p_speed: float, p_weight: float, p_rarity: String = "common") -> void:
		id = p_id
		name = p_name
		type = p_type
		damage = p_damage
		attack_speed = p_speed
		weight = p_weight
		rarity = p_rarity

var weapons: Array[Weapon] = []

signal weapon_equipped(weapon: Weapon)
signal weapon_unequipped

func _ready() -> void:
	set_state("equipped", null)
	_initialize_weapons()

func _initialize_weapons() -> void:
	weapons = [
		Weapon.new("wooden_sword", "Wooden Sword", "sword", 5.0, 1.2, 2.0, "common"),
		Weapon.new("iron_sword", "Iron Sword", "sword", 15.0, 1.0, 5.0, "uncommon"),
		Weapon.new("steel_sword", "Steel Sword", "sword", 25.0, 0.9, 6.0, "rare"),
		Weapon.new("wooden_bow", "Wooden Bow", "bow", 8.0, 1.5, 1.5, "common"),
		Weapon.new("longbow", "Longbow", "bow", 18.0, 1.3, 2.5, "uncommon"),
		Weapon.new("wooden_staff", "Wooden Staff", "staff", 6.0, 0.8, 3.0, "common"),
		Weapon.new("mage_staff", "Mage Staff", "staff", 20.0, 0.9, 2.5, "rare"),
		Weapon.new("dagger", "Dagger", "dagger", 12.0, 1.8, 1.0, "common"),
		Weapon.new("poisoned_dagger", "Poisoned Dagger", "dagger", 16.0, 1.7, 1.2, "rare"),
		Weapon.new("great_sword", "Great Sword", "sword", 35.0, 0.7, 8.0, "epic")
	]

func equip_weapon(weapon_id: String) -> bool:
	for weapon in weapons:
		if weapon.id == weapon_id:
			set_state("equipped", weapon)
			weapon_equipped.emit(weapon)
			emit_event("equipped", weapon_id)
			return true
	return false

func unequip_weapon() -> void:
	set_state("equipped", null)
	weapon_unequipped.emit()
	emit_event("unequipped", "weapon")

func get_equipped_weapon() -> Weapon:
	return get_state("equipped", null)

func get_weapon(weapon_id: String) -> Weapon:
	for weapon in weapons:
		if weapon.id == weapon_id:
			return weapon
	return null

func get_weapon_by_type(type: String) -> Array[Weapon]:
	return weapons.filter(func(w): return w.type == type)

func get_all_weapons() -> Array[Weapon]:
	return weapons

func get_weapon_damage() -> float:
	var weapon = get_equipped_weapon()
	return weapon.damage if weapon else 0.0

func get_weapon_text() -> String:
	var weapon = get_equipped_weapon()
	if not weapon:
		return "Weapon: None"
	return "%s\nDamage: %.0f | Speed: %.1f | Weight: %.1f" % [weapon.name, weapon.damage, weapon.attack_speed, weapon.weight]
