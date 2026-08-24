extends BaseSystemSimple

class_name PartySimple

class Member:
	var id: String
	var name: String
	var level: int
	var hp: float
	var max_hp: float
	var status: String
	var role: String = "warrior"
	var experience: float = 0.0
	var skills: Array[String] = []
	var stats: Dictionary = {"STR": 10, "AGI": 10, "INT": 10, "VIT": 10}
	var affection: Dictionary = {}
	var status_effects: Array[String] = []
	var position_in_party: int = 0
	var equipped_weapon: String = ""
	var equipped_armor: String = ""
	func _init(p_id: String, p_name: String, p_level: int = 1, p_role: String = "warrior") -> void:
		id = p_id
		name = p_name
		level = p_level
		role = p_role
		max_hp = (100.0 * p_level) + (stats["VIT"] * 5.0)
		hp = max_hp
		status = "active"

var party: Array[Member] = []

signal member_joined(member: Member)
signal member_left(member_id: String)
signal member_leveled_up(member: Member, new_level: int)
signal member_defeated(member_id: String)

func _ready() -> void:
	set_state("members", [])
	set_state("exp_pool", 0.0)
	set_state("gold_pool", 0.0)
	set_state("party_formation", "standard")
	set_state("party_bonds", {})
	set_state("synergy_bonuses", {})
	set_state("member_affections", {})
	set_state("total_battles", 0)
	set_state("victories", 0)
	set_state("member_fatigue", {})
	set_state("combat_history", [])
	set_state("skill_proficiency", {})
	set_state("role_performance", {})
	set_state("party_compatibility", {})
	set_state("member_equipment_history", {})

func add_member(member_id: String, name: String, level: int = 1, role: String = "warrior") -> bool:
	for m in party:
		if m.id == member_id:
			return false
	var member = Member.new(member_id, name, level, role)
	member.position_in_party = party.size()
	party.append(member)
	var affections = get_state("member_affections", {})
	affections[member_id] = {}
	set_state("member_affections", affections)
	member_joined.emit(member)
	emit_event("member_joined", {"id": member_id, "role": role})
	return true

func remove_member(member_id: String) -> bool:
	for i in range(party.size()):
		if party[i].id == member_id:
			party.remove_at(i)
			member_left.emit(member_id)
			emit_event("member_left", member_id)
			return true
	return false

func get_member(member_id: String) -> Member:
	for m in party:
		if m.id == member_id:
			return m
	return null

func heal_member(member_id: String, amount: float) -> void:
	var member = get_member(member_id)
	if member:
		member.hp = minf(member.hp + amount, member.max_hp)
		emit_event("member_healed", member_id)

func damage_member(member_id: String, amount: float) -> void:
	var member = get_member(member_id)
	if member:
		member.hp -= amount
		if member.hp <= 0:
			member.status = "defeated"
			member_defeated.emit(member_id)
			emit_event("member_defeated", member_id)
		else:
			emit_event("member_damaged", member_id)

func add_stat(member_id: String, stat: String, amount: int) -> void:
	var member = get_member(member_id)
	if member and stat in member.stats:
		member.stats[stat] += amount
		member.max_hp = (100.0 * member.level) + (member.stats["VIT"] * 5.0)
		emit_event("stat_increased", {"member": member_id, "stat": stat})

func add_status_effect(member_id: String, effect: String) -> void:
	var member = get_member(member_id)
	if member and effect not in member.status_effects:
		member.status_effects.append(effect)
		emit_event("status_effect_added", {"member": member_id, "effect": effect})

func remove_status_effect(member_id: String, effect: String) -> void:
	var member = get_member(member_id)
	if member:
		member.status_effects.erase(effect)

func level_up_member(member_id: String) -> void:
	var member = get_member(member_id)
	if member:
		member.level += 1
		var stat_gains = {"STR": randi() % 3 + 1, "AGI": randi() % 3 + 1, "INT": randi() % 2 + 1, "VIT": randi() % 3 + 2}
		for stat in stat_gains:
			add_stat(member_id, stat, stat_gains[stat])
		member.max_hp = (100.0 * member.level) + (member.stats["VIT"] * 5.0)
		member.hp = member.max_hp
		member_leveled_up.emit(member, member.level)
		emit_event("member_leveled_up", member_id)

func add_exp(amount: float) -> void:
	var pool = get_state("exp_pool", 0.0)
	pool += amount
	set_state("exp_pool", pool)
	if party.size() > 0:
		var per_member = pool / party.size()
		if per_member >= 100.0:
			for member in party:
				level_up_member(member.id)
			set_state("exp_pool", 0.0)

func add_gold(amount: float) -> void:
	var pool = get_state("gold_pool", 0.0)
	pool += amount
	set_state("gold_pool", pool)
	emit_event("gold_added", amount)

func set_party_formation(formation: String) -> void:
	set_state("party_formation", formation)
	emit_event("formation_changed", formation)

func get_formation_bonus(stat: String) -> float:
	var formation = get_state("party_formation", "standard")
	match formation:
		"offensive":
			return 1.2 if stat == "damage" else 0.8
		"defensive":
			return 1.3 if stat == "defense" else 0.9
		"balanced":
			return 1.0
		"speed":
			return 1.25 if stat == "speed" else 0.85
	return 1.0

func add_bond(member1_id: String, member2_id: String, bond_level: int) -> void:
	var affections = get_state("member_affections", {})
	if member1_id not in affections:
		affections[member1_id] = {}
	affections[member1_id][member2_id] = bond_level
	set_state("member_affections", affections)

func get_synergy_damage_bonus() -> float:
	var bonus = 1.0
	var affections = get_state("member_affections", {})
	var total_bond = 0
	for member1 in affections:
		for member2 in affections[member1]:
			total_bond += affections[member1][member2]
	bonus += (total_bond * 0.05)
	return bonus

func record_battle_result(victory: bool) -> void:
	var total = get_state("total_battles", 0) + 1
	set_state("total_battles", total)
	if victory:
		var wins = get_state("victories", 0) + 1
		set_state("victories", wins)
	emit_event("battle_recorded", {"victory": victory})

func get_gold() -> float:
	return get_state("gold_pool", 0.0)

func spend_gold(amount: float) -> bool:
	var gold = get_gold()
	if gold >= amount:
		set_state("gold_pool", gold - amount)
		emit_event("gold_spent", amount)
		return true
	return false

func get_party_stats() -> String:
	var formation = get_state("party_formation", "standard")
	var total_battles = get_state("total_battles", 0)
	var victories = get_state("victories", 0)
	var text = "Party [%s] | Battles: %d | Wins: %d\n" % [formation, total_battles, victories]
	for member in party:
		var status_text = ""
		if member.status_effects.size() > 0:
			status_text = " [%s]" % member.status_effects[0]
		text += "%s (%s) Lvl %d - HP: %.0f/%.0f%s\n" % [member.name, member.role, member.level, member.hp, member.max_hp, status_text]
	return text

func get_all_members() -> Array[Member]:
	return party

func get_active_members() -> Array[Member]:
	return party.filter(func(m): return m.status == "active")

func revive_member(member_id: String) -> void:
	var member = get_member(member_id)
	if member:
		member.status = "active"
		member.hp = member.max_hp
		emit_event("member_revived", member_id)

func apply_fatigue(member_id: String, fatigue_amount: float) -> void:
	var fatigue = get_state("member_fatigue", {})
	fatigue[member_id] = minf(fatigue.get(member_id, 0.0) + fatigue_amount, 1.0)
	set_state("member_fatigue", fatigue)
	emit_event("fatigue_applied", member_id)

func reduce_fatigue(member_id: String, reduction: float) -> void:
	var fatigue = get_state("member_fatigue", {})
	fatigue[member_id] = maxf(fatigue.get(member_id, 0.0) - reduction, 0.0)
	set_state("member_fatigue", fatigue)

func record_combat_action(member_id: String, action_type: String, success: bool) -> void:
	var history = get_state("combat_history", [])
	history.append({"member": member_id, "action": action_type, "success": success, "time": Time.get_ticks_msec()})
	if history.size() > 100:
		history.pop_front()
	set_state("combat_history", history)
	emit_event("combat_action_recorded", member_id)

func track_skill_proficiency(member_id: String, skill: String, usage_count: int = 1) -> void:
	var profs = get_state("skill_proficiency", {})
	if member_id not in profs:
		profs[member_id] = {}
	profs[member_id][skill] = profs[member_id].get(skill, 0) + usage_count
	set_state("skill_proficiency", profs)

func record_role_performance(member_id: String, role: String, damage_dealt: float, damage_taken: float) -> void:
	var perf = get_state("role_performance", {})
	if member_id not in perf:
		perf[member_id] = []
	perf[member_id].append({"role": role, "damage_dealt": damage_dealt, "damage_taken": damage_taken, "time": Time.get_ticks_msec()})
	if perf[member_id].size() > 50:
		perf[member_id].pop_front()
	set_state("role_performance", perf)

func calculate_compatibility(member1_id: String, member2_id: String) -> float:
	var compat = get_state("party_compatibility", {})
	var key = "%s_%s" % [minf(member1_id, member2_id), maxf(member1_id, member2_id)]
	return compat.get(key, 0.5)

func update_compatibility(member1_id: String, member2_id: String, compatibility: float) -> void:
	var compat = get_state("party_compatibility", {})
	var key = "%s_%s" % [minf(member1_id, member2_id), maxf(member1_id, member2_id)]
	compat[key] = clampf(compatibility, 0.0, 1.0)
	set_state("party_compatibility", compat)
	emit_event("compatibility_updated", {"m1": member1_id, "m2": member2_id})

func record_equipment_change(member_id: String, equipment_type: String, new_item: String) -> void:
	var equip_hist = get_state("member_equipment_history", {})
	if member_id not in equip_hist:
		equip_hist[member_id] = []
	equip_hist[member_id].append({"type": equipment_type, "item": new_item, "time": Time.get_ticks_msec()})
	if equip_hist[member_id].size() > 30:
		equip_hist[member_id].pop_front()
	set_state("member_equipment_history", equip_hist)
	emit_event("equipment_changed", member_id)

func get_average_fatigue() -> float:
	var fatigue = get_state("member_fatigue", {})
	if fatigue.is_empty():
		return 0.0
	var total = 0.0
	for f in fatigue.values():
		total += f
	return total / fatigue.size()

func get_member_fatigue(member_id: String) -> float:
	var fatigue = get_state("member_fatigue", {})
	return fatigue.get(member_id, 0.0)
