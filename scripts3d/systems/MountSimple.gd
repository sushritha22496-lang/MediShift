extends BaseSystemSimple

class_name MountSimple

class Mount:
	var id: String
	var name: String
	var speed: float
	var stamina: float
	var max_stamina: float
	var level: int
	var rarity: String
	var health: float = 100.0
	var max_health: float = 100.0
	var affection: float = 0.0
	var hunger: float = 50.0
	var happiness: float = 100.0
	var abilities: Array[String] = []
	var stats: Dictionary = {"agility": 10, "endurance": 10, "power": 10}
	var special_ability: String = ""
	var equipment: Dictionary = {"saddle": "", "bridle": "", "shoes": ""}
	var injuries: Array[String] = []
	var experience: float = 0.0
	func _init(p_id: String, p_name: String, p_speed: float, p_stamina: float, p_rarity: String = "common") -> void:
		id = p_id
		name = p_name
		speed = p_speed
		max_stamina = p_stamina
		stamina = p_stamina
		level = 1
		rarity = p_rarity
		_initialize_rarity_abilities(p_rarity)

	func _initialize_rarity_abilities(p_rarity: String) -> void:
		match p_rarity:
			"common":
				abilities = ["trot"]
				special_ability = ""
			"uncommon":
				abilities = ["trot", "gallop"]
				special_ability = "swift_run"
			"rare":
				abilities = ["trot", "gallop", "charge"]
				special_ability = "wind_dash"
			"epic":
				abilities = ["trot", "gallop", "charge", "fly"]
				special_ability = "dragon_flight"

var mounts: Array[Mount] = []
var owned_mounts: Array[Mount] = []

signal mount_acquired(mount: Mount)
signal mount_mounted(mount: Mount)
signal mount_dismounted
signal mount_leveled_up(mount: Mount, new_level: int)

func _ready() -> void:
	set_state("active_mount", null)
	set_state("mount_exp", {})
	set_state("mount_care_log", {})
	set_state("mount_affections", {})
	set_state("mount_breeding", {})
	set_state("total_distance_traveled", 0.0)
	set_state("acquisition_history", [])
	set_state("care_history", [])
	set_state("affection_progression", [])
	set_state("stamina_tracking", [])
	set_state("mount_statistics", {})
	_initialize_mounts()

func _initialize_mounts() -> void:
	mounts = [
		Mount.new("horse", "Horse", 25.0, 100.0, "common"),
		Mount.new("stag", "Enchanted Stag", 30.0, 120.0, "uncommon"),
		Mount.new("griffin", "Griffin", 35.0, 150.0, "rare"),
		Mount.new("dragon", "Dragon Hatchling", 40.0, 200.0, "epic")
	]

func acquire_mount(mount_id: String) -> bool:
	var mount = _get_mount_from_list(mount_id, mounts)
	if mount and mount not in owned_mounts:
		var new_mount = Mount.new(mount.id, mount.name, mount.speed, mount.max_stamina, mount.rarity)
		owned_mounts.append(new_mount)
		var affections = get_state("mount_affections", {})
		affections[mount_id] = 0.0
		set_state("mount_affections", affections)
		_record_acquisition(mount_id, mount.rarity)
		mount_acquired.emit(new_mount)
		emit_event("mount_acquired", mount_id)
		return true
	return false

func mount(mount_id: String) -> bool:
	var mount = _get_mount_from_list(mount_id, owned_mounts)
	if mount:
		set_state("active_mount", mount)
		mount_mounted.emit(mount)
		emit_event("mount_mounted", mount_id)
		return true
	return false

func dismount() -> void:
	set_state("active_mount", null)
	mount_dismounted.emit()
	emit_event("mount_dismounted", "player")

func get_active_mount() -> Mount:
	return get_state("active_mount", null)

func is_mounted() -> bool:
	return get_active_mount() != null

func feed_mount(mount_id: String) -> void:
	var mount = _get_mount_from_list(mount_id, owned_mounts)
	if mount:
		mount.hunger = minf(mount.hunger + 30.0, 100.0)
		mount.happiness = minf(mount.happiness + 5.0, 100.0)
		_record_care_action(mount_id, "feed", mount.happiness)
		_increase_mount_affection(mount_id, 0.5)
		_record_affection_change(mount_id, get_mount_affection(mount_id))
		emit_event("mount_fed", mount_id)

func heal_mount(mount_id: String, amount: float) -> void:
	var mount = _get_mount_from_list(mount_id, owned_mounts)
	if mount:
		mount.health = minf(mount.health + amount, mount.max_health)
		emit_event("mount_healed", mount_id)

func injure_mount(mount_id: String, injury: String) -> void:
	var mount = _get_mount_from_list(mount_id, owned_mounts)
	if mount and injury not in mount.injuries:
		mount.injuries.append(injury)
		mount.happiness -= 10.0
		emit_event("mount_injured", {"id": mount_id, "injury": injury})

func _increase_mount_affection(mount_id: String, amount: float) -> void:
	var affections = get_state("mount_affections", {})
	affections[mount_id] = affections.get(mount_id, 0.0) + amount
	set_state("mount_affections", affections)

func get_mount_affection(mount_id: String) -> float:
	var affections = get_state("mount_affections", {})
	return affections.get(mount_id, 0.0)

func use_special_ability(mount_id: String) -> bool:
	var mount = _get_mount_from_list(mount_id, owned_mounts)
	if mount and mount.special_ability != "":
		mount.stamina -= 20.0
		emit_event("ability_used", {"mount": mount_id, "ability": mount.special_ability})
		return true
	return false

func level_up_mount(mount_id: String) -> void:
	var mount = _get_mount_from_list(mount_id, owned_mounts)
	if mount:
		mount.level += 1
		mount.speed += 2.0 + (mount.stats["agility"] * 0.1)
		mount.max_stamina += 20.0 + (mount.stats["endurance"] * 0.5)
		mount.stamina = mount.max_stamina
		var stat_gains = {"agility": randi() % 2 + 1, "endurance": randi() % 2 + 1, "power": randi() % 2 + 1}
		for stat in stat_gains:
			mount.stats[stat] += stat_gains[stat]
		mount_leveled_up.emit(mount, mount.level)
		emit_event("mount_leveled_up", mount_id)

func restore_mount_stamina(mount_id: String, amount: float) -> void:
	var mount = _get_mount_from_list(mount_id, owned_mounts)
	if mount:
		mount.stamina = minf(mount.stamina + amount, mount.max_stamina)
		emit_event("mount_stamina_restored", mount_id)

func drain_mount_stamina(mount_id: String, amount: float) -> void:
	var mount = _get_mount_from_list(mount_id, owned_mounts)
	if mount:
		var hunger_drain = 1.0 + ((100.0 - mount.hunger) * 0.01)
		mount.stamina -= (amount * hunger_drain)
		mount.hunger -= 0.5
		_record_stamina_change(mount_id, mount.stamina)
		if mount.stamina <= 0:
			mount.stamina = 0
			emit_event("mount_tired", mount_id)

func travel_distance(mount_id: String, distance: float) -> void:
	var mount = _get_mount_from_list(mount_id, owned_mounts)
	if mount:
		var total = get_state("total_distance_traveled", 0.0)
		set_state("total_distance_traveled", total + distance)
		drain_mount_stamina(mount_id, distance / 10.0)
		mount.experience += distance / 5.0
		emit_event("traveled", {"mount": mount_id, "distance": distance})

func get_owned_mounts() -> Array[Mount]:
	return owned_mounts

func get_all_mounts() -> Array[Mount]:
	return mounts

func get_mount(mount_id: String) -> Mount:
	return _get_mount_from_list(mount_id, mounts)

func get_mount_speed_bonus() -> float:
	var active = get_active_mount()
	if active:
		return active.speed
	return 0.0

func equip_mount_equipment(mount_id: String, slot: String, equipment_id: String) -> void:
	var mount = _get_mount_from_list(mount_id, owned_mounts)
	if mount and slot in mount.equipment:
		mount.equipment[slot] = equipment_id
		mount.speed += 1.0
		emit_event("mount_equipment_equipped", {"mount": mount_id, "slot": slot, "equipment": equipment_id})

func get_mount_text() -> String:
	var active = get_active_mount()
	if not active:
		return "Mount: None | Owned: %d" % owned_mounts.size()
	var affection = get_mount_affection(active.id)
	var status = ""
	if active.injuries.size() > 0:
		status = " [INJURED]"
	return "%s (Lvl %d) %s\nSpeed: %.0f | Stamina: %.0f/%.0f | Happiness: %.0f | Affection: %.1f" % [active.name, active.level, status, active.speed, active.stamina, active.max_stamina, active.happiness, affection]

func _record_acquisition(mount_id: String, rarity: String) -> void:
	var history = get_state("acquisition_history", [])
	history.append({"mount": mount_id, "rarity": rarity, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("acquisition_history", history)

func _record_care_action(mount_id: String, action_type: String, happiness: float) -> void:
	var history = get_state("care_history", [])
	history.append({"mount": mount_id, "action": action_type, "happiness": happiness, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("care_history", history)

func _record_affection_change(mount_id: String, affection: float) -> void:
	var tracking = get_state("affection_progression", [])
	tracking.append({"mount": mount_id, "affection": affection, "time": Time.get_ticks_msec()})
	if tracking.size() > 50:
		tracking.pop_front()
	set_state("affection_progression", tracking)

func _record_stamina_change(mount_id: String, stamina: float) -> void:
	var tracking = get_state("stamina_tracking", [])
	tracking.append({"mount": mount_id, "stamina": stamina, "time": Time.get_ticks_msec()})
	if tracking.size() > 50:
		tracking.pop_front()
	set_state("stamina_tracking", tracking)

func update_mount_statistics() -> void:
	var stats = get_state("mount_statistics", {})
	stats["owned_mounts"] = owned_mounts.size()
	stats["total_distance"] = get_state("total_distance_traveled", 0.0)
	stats["acquisition_count"] = get_state("acquisition_history", []).size()
	stats["care_actions"] = get_state("care_history", []).size()
	if not owned_mounts.is_empty():
		var avg_affection = 0.0
		for mount in owned_mounts:
			avg_affection += get_mount_affection(mount.id)
		stats["average_affection"] = avg_affection / float(owned_mounts.size())
	set_state("mount_statistics", stats)

func get_mount_statistics() -> Dictionary:
	update_mount_statistics()
	return get_state("mount_statistics", {})

func _get_mount_from_list(mount_id: String, mount_list: Array[Mount]) -> Mount:
	for mount in mount_list:
		if mount.id == mount_id:
			return mount
	return null
