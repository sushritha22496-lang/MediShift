extends BaseSystemSimple

class_name PartySimple

class Member:
	var id: String
	var name: String
	var level: int
	var hp: float
	var max_hp: float
	var status: String
	func _init(p_id: String, p_name: String, p_level: int = 1) -> void:
		id = p_id
		name = p_name
		level = p_level
		max_hp = 100.0 * p_level
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

func add_member(member_id: String, name: String, level: int = 1) -> bool:
	for m in party:
		if m.id == member_id:
			return false
	var member = Member.new(member_id, name, level)
	party.append(member)
	member_joined.emit(member)
	emit_event("member_joined", member_id)
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

func level_up_member(member_id: String) -> void:
	var member = get_member(member_id)
	if member:
		member.level += 1
		member.max_hp = 100.0 * member.level
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
	var text = "Party:\n"
	for member in party:
		text += "%s (Lvl %d) - HP: %.0f/%.0f\n" % [member.name, member.level, member.hp, member.max_hp]
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
