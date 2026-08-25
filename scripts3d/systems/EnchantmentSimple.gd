extends BaseSystemSimple

class_name EnchantmentSimple

class Enchantment:
	var id: String
	var name: String
	var power: float
	var cost: float
	var bonus_type: String
	var level: int
	var max_level: int
	var rarity: String
	var success_rate: float
	var durability: float
	var max_durability: float
	var synergies: Array[String]
	func _init(p_id: String, p_name: String, p_power: float, p_cost: float, p_bonus: String) -> void:
		id = p_id
		name = p_name
		power = p_power
		cost = p_cost
		bonus_type = p_bonus
		level = 1
		max_level = 5
		rarity = "common"
		success_rate = 0.7
		durability = 100.0
		max_durability = 100.0
		synergies = []

var available_enchantments: Array[Enchantment] = []

signal enchantment_applied(equipment: String, enchantment: Enchantment)
signal enchantment_failed(reason: String)
signal enchantment_upgraded(item: String, enchantment_id: String, new_level: int)
signal synergy_triggered(items: Array)
signal enchantment_decayed(enchantment_id: String)
signal cascading_effect_triggered(effect: String)

func _ready() -> void:
	set_state("items", {})
	set_state("enchantment_slots", {})
	set_state("enchantment_history", [])
	set_state("enchantment_decay", {})
	set_state("cascade_chains", [])
	set_state("failure_consequences", {})
	set_state("application_history", [])
	set_state("upgrade_history", [])
	set_state("synergy_tracking", [])
	set_state("success_failure_rates", {})
	set_state("enchantment_statistics", {})
	set_state("disenchant_history", [])
	_initialize_enchantments()

func _initialize_enchantments() -> void:
	var ench1 = Enchantment.new("sharpness", "Sharpness", 10.0, 500, "damage")
	ench1.synergies = ["power_boost"]
	available_enchantments.append(ench1)
	var ench2 = Enchantment.new("hardness", "Hardness", 8.0, 450, "defense")
	ench2.synergies = ["shield"]
	available_enchantments.append(ench2)
	available_enchantments.append(Enchantment.new("swiftness", "Swiftness", 15.0, 600, "speed"))
	available_enchantments.append(Enchantment.new("regeneration", "Regeneration", 12.0, 700, "healing"))

func enchant_item(item_name: String, enchantment_id: String, gold_available: float) -> bool:
	var enchantment = _find_enchantment(enchantment_id)
	if not enchantment:
		enchantment_failed.emit("Enchantment not found")
		_record_success_failure(enchantment_id, false)
		return false
	if gold_available < enchantment.cost:
		enchantment_failed.emit("Not enough gold")
		_record_success_failure(enchantment_id, false)
		return false
	if randf() > enchantment.success_rate:
		enchantment_failed.emit("Enchantment failed")
		_record_success_failure(enchantment_id, false)
		emit_event("enchantment_failed", enchantment_id)
		return false
	var items = get_state("items", {})
	if not item_name in items:
		items[item_name] = []
	items[item_name].append(enchantment)
	_record_application(item_name, enchantment_id)
	_record_success_failure(enchantment_id, true)
	enchantment_applied.emit(item_name, enchantment)
	_check_synergies(item_name)
	emit_event("enchanted", item_name)
	return true

func _check_synergies(item_name: String) -> void:
	var enchantments = get_item_enchantments(item_name)
	var synergy_triggered = false
	for ench in enchantments:
		for synergy_id in ench.synergies:
			for other_ench in enchantments:
				if other_ench.id == synergy_id:
					_record_synergy(item_name, ench.id, synergy_id)
					synergy_triggered.emit([item_name, ench.id, synergy_id])
					emit_event("synergy_triggered", {"item": item_name, "enchantments": [ench.id, synergy_id]})

func _find_enchantment(enchantment_id: String) -> Enchantment:
	for ench in available_enchantments:
		if ench.id == enchantment_id:
			return ench
	return null

func get_item_enchantments(item_name: String) -> Array:
	var items = get_state("items", {})
	return items.get(item_name, [])

func get_enchantment_bonus(item_name: String, bonus_type: String) -> float:
	var total = 0.0
	for ench in get_item_enchantments(item_name):
		if ench.bonus_type == bonus_type:
			total += ench.power
	return total

func upgrade_enchantment(item_name: String, enchantment_id: String, gold_available: float) -> bool:
	var enchantments = get_item_enchantments(item_name)
	for ench in enchantments:
		if ench.id == enchantment_id:
			if ench.level >= ench.max_level:
				return false
			var upgrade_cost = ench.cost * (1.0 + (ench.level * 0.25))
			if gold_available < upgrade_cost:
				enchantment_failed.emit("Not enough gold for upgrade")
				return false
			ench.level += 1
			ench.power *= 1.2
			ench.cost = upgrade_cost
			_record_upgrade(item_name, enchantment_id, ench.level)
			enchantment_upgraded.emit(item_name, enchantment_id, ench.level)
			emit_event("enchantment_upgraded", enchantment_id)
			return true
	return false

func disenchant_item(item_name: String, enchantment_id: String) -> float:
	var enchantments = get_item_enchantments(item_name)
	for i in range(enchantments.size()):
		if enchantments[i].id == enchantment_id:
			var ench = enchantments[i]
			var refund = ench.cost * 0.5 * (ench.level * 0.1 + 1.0)
			enchantments.remove_at(i)
			var history = get_state("disenchant_history", [])
			history.append({"item": item_name, "enchantment": enchantment_id, "refund": refund, "time": Time.get_ticks_msec()})
			if history.size() > 50:
				history.pop_front()
			set_state("disenchant_history", history)
			emit_event("disenchanted", enchantment_id)
			return refund
	return 0.0

func get_enchantments_text() -> String:
	var text = "Available Enchantments:\n"
	for ench in available_enchantments:
		text += "%s (Lvl %d) - %d gold\n" % [ench.name, ench.level, int(ench.cost)]
	return text

func get_available_enchantments() -> Array[Enchantment]:
	return available_enchantments

func get_enchantment_effectiveness(item_name: String) -> float:
	var enchantments = get_item_enchantments(item_name)
	var total_effectiveness = 1.0
	for ench in enchantments:
		total_effectiveness *= 1.0 + (ench.level * 0.05)
	return total_effectiveness

func update_enchantment_decay(delta: float) -> void:
	var decay = get_state("enchantment_decay", {})
	var items = get_state("items", {})
	for item_name in items:
		if item_name not in decay:
			decay[item_name] = 0.0
		decay[item_name] += delta * 0.1
		if decay[item_name] >= 100.0:
			decay[item_name] = 0.0
			enchantment_decayed.emit(item_name)
			emit_event("enchantment_decayed", item_name)
	set_state("enchantment_decay", decay)

func trigger_cascading_effect(initial_effect: String, power: float = 1.0) -> void:
	var cascades = get_state("cascade_chains", [])
	cascades.append({"initial": initial_effect, "power": power, "triggered_at": Time.get_ticks_msec()})
	if cascades.size() > 50:
		cascades.pop_front()
	set_state("cascade_chains", cascades)
	cascading_effect_triggered.emit(initial_effect)
	emit_event("cascade_triggered", initial_effect)

func record_failure_consequence(item_name: String, consequence: String) -> void:
	var consequences = get_state("failure_consequences", {})
	if item_name not in consequences:
		consequences[item_name] = []
	consequences[item_name].append({"type": consequence, "time": Time.get_ticks_msec()})
	set_state("failure_consequences", consequences)
	emit_event("failure_recorded", item_name)

func get_enchantment_decay_rate(item_name: String) -> float:
	var decay = get_state("enchantment_decay", {})
	return decay.get(item_name, 0.0)

func _record_application(item_name: String, enchantment_id: String) -> void:
	var history = get_state("application_history", [])
	history.append({"item": item_name, "enchantment": enchantment_id, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("application_history", history)

func _record_upgrade(item_name: String, enchantment_id: String, level: int) -> void:
	var history = get_state("upgrade_history", [])
	history.append({"item": item_name, "enchantment": enchantment_id, "level": level, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("upgrade_history", history)

func _record_synergy(item_name: String, ench_id_1: String, ench_id_2: String) -> void:
	var tracking = get_state("synergy_tracking", [])
	tracking.append({"item": item_name, "synergies": [ench_id_1, ench_id_2], "time": Time.get_ticks_msec()})
	if tracking.size() > 50:
		tracking.pop_front()
	set_state("synergy_tracking", tracking)

func _record_success_failure(enchantment_id: String, success: bool) -> void:
	var rates = get_state("success_failure_rates", {})
	if enchantment_id not in rates:
		rates[enchantment_id] = {"successes": 0, "failures": 0}
	if success:
		rates[enchantment_id]["successes"] += 1
	else:
		rates[enchantment_id]["failures"] += 1
	set_state("success_failure_rates", rates)

func update_enchantment_statistics() -> void:
	var stats = get_state("enchantment_statistics", {})
	var rates = get_state("success_failure_rates", {})
	var total_success = 0
	var total_failure = 0
	for ench_id in rates:
		total_success += rates[ench_id]["successes"]
		total_failure += rates[ench_id]["failures"]
	stats["total_applications"] = get_state("application_history", []).size()
	stats["total_upgrades"] = get_state("upgrade_history", []).size()
	stats["synergies_triggered"] = get_state("synergy_tracking", []).size()
	stats["total_success"] = total_success
	stats["total_failure"] = total_failure
	stats["overall_success_rate"] = float(total_success) / float(total_success + total_failure) if (total_success + total_failure) > 0 else 0.0
	stats["disenchants"] = get_state("disenchant_history", []).size()
	stats["cascades_triggered"] = get_state("cascade_chains", []).size()
	stats["available_enchantments"] = available_enchantments.size()
	set_state("enchantment_statistics", stats)

func get_enchantment_statistics() -> Dictionary:
	update_enchantment_statistics()
	return get_state("enchantment_statistics", {})

func get_cascading_effects() -> Array:
	return get_state("cascade_chains", [])
