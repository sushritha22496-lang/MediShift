extends BaseSystemSimple

class_name BountySimple

class Bounty:
	var id: String
	var target: String
	var reward: float
	var difficulty: int
	var status: String
	var description: String
	var time_limit: int = 0
	var evidence_required: int = 1
	var evidence_collected: int = 0
	var prerequisites: Array[String] = []
	var risk_level: float = 0.5
	var witness_count: int = 0
	var witness_safety: float = 1.0
	var client_reputation: float = 1.0
	var location_tags: Array[String] = []
	func _init(p_id: String, p_target: String, p_reward: float, p_diff: int) -> void:
		id = p_id
		target = p_target
		reward = p_reward
		difficulty = p_diff
		status = "active"
		description = ""
		time_limit = (p_diff * 30) + 60
		risk_level = 0.2 + (p_diff * 0.2)

var bounties: Array[Bounty] = []

signal bounty_accepted(bounty: Bounty)
signal bounty_completed(bounty: Bounty, reward: float)
signal bounty_abandoned(bounty_id: String)

func _ready() -> void:
	set_state("active_bounties", [])
	set_state("completed_bounties", [])
	set_state("total_earned", 0.0)
	set_state("bounty_reputation", {})
	set_state("failed_bounties", [])
	set_state("evidence_tracker", {})
	set_state("bounty_timers", {})
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
	bounties[0].evidence_required = 1
	bounties[0].witness_count = 2
	bounties[0].location_tags = ["cave", "bandits"]

	bounties[1].description = "Hunt down the wolf pack near the forest"
	bounties[1].evidence_required = 3
	bounties[1].witness_count = 0
	bounties[1].location_tags = ["forest", "wild"]

	bounties[2].description = "Defeat the corrupted guardian blocking the path"
	bounties[2].prerequisites = ["b1"]
	bounties[2].evidence_required = 1

	bounties[3].description = "Catch the treasure hunter stealing artifacts"
	bounties[3].evidence_required = 2
	bounties[3].witness_count = 1

	bounties[4].description = "Banish the wraith haunting the ruins"
	bounties[4].prerequisites = ["b3"]
	bounties[4].evidence_required = 2
	bounties[4].risk_level = 0.9

func accept_bounty(bounty_id: String) -> bool:
	var bounty = _get_bounty(bounty_id)
	if bounty and bounty.status == "active":
		if not _check_bounty_prerequisites(bounty):
			return false
		var active = get_state("active_bounties", [])
		active.append(bounty_id)
		set_state("active_bounties", active)
		var evidence_tracker = get_state("evidence_tracker", {})
		evidence_tracker[bounty_id] = 0
		set_state("evidence_tracker", evidence_tracker)
		bounty_accepted.emit(bounty)
		emit_event("bounty_accepted", bounty_id)
		return true
	return false

func _check_bounty_prerequisites(bounty: Bounty) -> bool:
	var completed = get_state("completed_bounties", [])
	for prereq_id in bounty.prerequisites:
		if prereq_id not in completed:
			return false
	return true

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
		var reward = _calculate_final_reward(bounty, bounty_id)
		var total = get_state("total_earned", 0.0)
		total += reward
		set_state("total_earned", total)
		_update_bounty_reputation(bounty_id, true)
		bounty_completed.emit(bounty, reward)
		emit_event("bounty_completed", {"id": bounty_id, "reward": reward})
		return reward
	return 0.0

func _calculate_final_reward(bounty: Bounty, bounty_id: String) -> float:
	var evidence = get_state("evidence_tracker", {})
	var evidence_bonus = float(evidence.get(bounty_id, 0)) / float(bounty.evidence_required)
	var witness_bonus = 1.0 + (bounty.witness_safety - 1.0)
	var reputation = get_state("bounty_reputation", {})
	var rep_multiplier = 1.0 + (reputation.get(bounty_id, 0.0) * 0.1)
	return bounty.reward * (1.0 + evidence_bonus * 0.2) * witness_bonus * rep_multiplier

func _update_bounty_reputation(bounty_id: String, success: bool) -> void:
	var rep = get_state("bounty_reputation", {})
	var change = 0.5 if success else -0.3
	rep[bounty_id] = rep.get(bounty_id, 0.0) + change
	set_state("bounty_reputation", rep)

func abandon_bounty(bounty_id: String) -> bool:
	var active = get_state("active_bounties", [])
	if bounty_id in active:
		active.erase(bounty_id)
		set_state("active_bounties", active)
		var failed = get_state("failed_bounties", [])
		failed.append(bounty_id)
		set_state("failed_bounties", failed)
		_update_bounty_reputation(bounty_id, false)
		bounty_abandoned.emit(bounty_id)
		emit_event("bounty_abandoned", bounty_id)
		return true
	return false

func collect_evidence(bounty_id: String) -> void:
	var evidence = get_state("evidence_tracker", {})
	evidence[bounty_id] = evidence.get(bounty_id, 0) + 1
	set_state("evidence_tracker", evidence)
	emit_event("evidence_collected", {"bounty": bounty_id})

func get_bounty_progress(bounty_id: String) -> float:
	var bounty = _get_bounty(bounty_id)
	if not bounty:
		return 0.0
	var evidence = get_state("evidence_tracker", {})
	var collected = evidence.get(bounty_id, 0)
	return float(collected) / float(bounty.evidence_required)

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

func get_bounty_risk(bounty_id: String) -> float:
	var bounty = _get_bounty(bounty_id)
	return bounty.risk_level if bounty else 0.0

func get_failed_bounties_count() -> int:
	return get_state("failed_bounties", []).size()

func get_bounty_text() -> String:
	var active = get_active_bounties()
	var failed = get_state("failed_bounties", [])
	var text = "Bounties: %d Active | Failed: %d | Earned: %.0f\n" % [active.size(), failed.size(), get_total_earned()]
	for bounty in active.slice(0, 3):
		var progress = get_bounty_progress(bounty.id)
		text += "[★%d] %s - %.0f (%.0f%%)\n" % [bounty.difficulty, bounty.target, bounty.reward, progress * 100.0]
	return text

func _get_bounty(bounty_id: String) -> Bounty:
	for bounty in bounties:
		if bounty.id == bounty_id:
			return bounty
	return null
