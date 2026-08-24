extends BaseSystemSimple

class_name BountySimple

class Bounty:
	var id: String
	var target: String
	var reward: float
	var difficulty: int
	var status: String
	var description: String
	func _init(p_id: String, p_target: String, p_reward: float, p_diff: int) -> void:
		id = p_id
		target = p_target
		reward = p_reward
		difficulty = p_diff
		status = "active"
		description = ""

var bounties: Array[Bounty] = []

signal bounty_accepted(bounty: Bounty)
signal bounty_completed(bounty: Bounty, reward: float)
signal bounty_abandoned(bounty_id: String)

func _ready() -> void:
	set_state("active_bounties", [])
	set_state("completed_bounties", [])
	set_state("total_earned", 0.0)
	_initialize_bounties()

func _initialize_bounties() -> void:
	bounties = [
		Bounty.new("b1", "Bandit Leader", 100.0, 2),
		Bounty.new("b2", "Wild Wolf Pack", 50.0, 1),
		Bounty.new("b3", "Corrupted Guardian", 200.0, 3),
		Bounty.new("b4", "Treasure Hunter", 75.0, 2),
		Bounty.new("b5", "Ancient Wraith", 250.0, 4)
	]
	bounties[0].description = "Eliminate the bandit leader terrorizing the village"
	bounties[1].description = "Hunt down the wolf pack near the forest"
	bounties[2].description = "Defeat the corrupted guardian blocking the path"
	bounties[3].description = "Catch the treasure hunter stealing artifacts"
	bounties[4].description = "Banish the wraith haunting the ruins"

func accept_bounty(bounty_id: String) -> bool:
	var bounty = _get_bounty(bounty_id)
	if bounty and bounty.status == "active":
		var active = get_state("active_bounties", [])
		active.append(bounty_id)
		set_state("active_bounties", active)
		bounty_accepted.emit(bounty)
		emit_event("bounty_accepted", bounty_id)
		return true
	return false

func complete_bounty(bounty_id: String) -> float:
	var bounty = _get_bounty(bounty_id)
	if bounty:
		bounty.status = "completed"
		var active = get_state("active_bounties", [])
		active.erase(bounty_id)
		var completed = get_state("completed_bounties", [])
		completed.append(bounty_id)
		set_state("active_bounties", active)
		set_state("completed_bounties", completed)
		var total = get_state("total_earned", 0.0)
		total += bounty.reward
		set_state("total_earned", total)
		bounty_completed.emit(bounty, bounty.reward)
		emit_event("bounty_completed", bounty_id)
		return bounty.reward
	return 0.0

func abandon_bounty(bounty_id: String) -> bool:
	var active = get_state("active_bounties", [])
	if bounty_id in active:
		active.erase(bounty_id)
		set_state("active_bounties", active)
		bounty_abandoned.emit(bounty_id)
		emit_event("bounty_abandoned", bounty_id)
		return true
	return false

func get_bounty(bounty_id: String) -> Bounty:
	return _get_bounty(bounty_id)

func get_active_bounties() -> Array[Bounty]:
	var active_ids = get_state("active_bounties", [])
	var active: Array[Bounty] = []
	for b in bounties:
		if b.id in active_ids:
			active.append(b)
	return active

func get_available_bounties() -> Array[Bounty]:
	return bounties.filter(func(b): return b.status == "active")

func get_bounties_by_difficulty(difficulty: int) -> Array[Bounty]:
	return bounties.filter(func(b): return b.difficulty == difficulty)

func get_total_earned() -> float:
	return get_state("total_earned", 0.0)

func get_bounty_text() -> String:
	var active = get_active_bounties()
	var text = "Bounties: %d Active | Earned: %.0f\n" % [active.size(), get_total_earned()]
	for bounty in active.slice(0, 3):
		text += "[★%d] %s - %.0f\n" % [bounty.difficulty, bounty.target, bounty.reward]
	return text

func _get_bounty(bounty_id: String) -> Bounty:
	for bounty in bounties:
		if bounty.id == bounty_id:
			return bounty
	return null
