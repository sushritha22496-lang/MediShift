extends BaseSystemSimple

class_name RewardSimple

class Reward:
	var id: String
	var name: String
	var reward_type: String
	var value: float
	var quantity: int
	func _init(p_id: String, p_name: String, p_type: String, p_value: float, p_qty: int = 1) -> void:
		id = p_id
		name = p_name
		reward_type = p_type
		value = p_value
		quantity = p_qty

var reward_pool: Array[Reward] = []

signal reward_given(reward: Reward)
signal reward_claimed(reward_id: String)

func _ready() -> void:
	set_state("pending_rewards", [])
	set_state("claimed_rewards", [])
	set_state("reward_multiplier", 1.0)
	set_state("reward_conditions", {})
	set_state("reward_history", [])
	_initialize_rewards()

func _initialize_rewards() -> void:
	reward_pool = [
		Reward.new("r1", "Gold", "currency", 100.0),
		Reward.new("r2", "Experience", "exp", 250.0),
		Reward.new("r3", "Health Potion", "potion", 25.0, 3),
		Reward.new("r4", "Mana Potion", "potion", 20.0, 2),
		Reward.new("r5", "Rare Gem", "item", 500.0)
	]

func give_reward(reward_id: String) -> bool:
	for reward in reward_pool:
		if reward.id == reward_id:
			var pending = get_state("pending_rewards", [])
			pending.append(reward_id)
			set_state("pending_rewards", pending)
			_record_reward_event(reward_id, "given", reward.value)
			reward_given.emit(reward)
			emit_event("reward_given", reward_id)
			return true
	return false

func claim_reward(reward_id: String) -> Reward:
	for reward in reward_pool:
		if reward.id == reward_id:
			var pending = get_state("pending_rewards", [])
			pending.erase(reward_id)
			var claimed = get_state("claimed_rewards", [])
			claimed.append(reward_id)
			set_state("pending_rewards", pending)
			set_state("claimed_rewards", claimed)
			_record_reward_event(reward_id, "claimed", reward.value * get_reward_multiplier())
			reward_claimed.emit(reward_id)
			emit_event("reward_claimed", reward_id)
			return reward
	return null

func _record_reward_event(reward_id: String, action: String, value: float) -> void:
	var history = get_state("reward_history", [])
	history.append({"reward": reward_id, "action": action, "value": value, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("reward_history", history)

func get_pending_rewards() -> Array[Reward]:
	var pending_ids = get_state("pending_rewards", [])
	var pending: Array[Reward] = []
	for reward in reward_pool:
		if reward.id in pending_ids:
			pending.append(reward)
	return pending

func get_reward_count() -> int:
	return get_state("pending_rewards", []).size()

func get_reward_text() -> String:
	var pending = get_pending_rewards()
	var text = "Pending Rewards: %d\n" % pending.size()
	for reward in pending.slice(0, 3):
		text += "• %s (%.0f)\n" % [reward.name, reward.value]
	return text

func set_reward_multiplier(multiplier: float) -> void:
	set_state("reward_multiplier", clampf(multiplier, 0.1, 5.0))
	emit_event("multiplier_changed", multiplier)

func get_reward_multiplier() -> float:
	return get_state("reward_multiplier", 1.0)

func add_reward_condition(reward_id: String, condition: String) -> void:
	var conditions = get_state("reward_conditions", {})
	if reward_id not in conditions:
		conditions[reward_id] = []
	conditions[reward_id].append(condition)
	set_state("reward_conditions", conditions)

func check_reward_conditions(reward_id: String) -> bool:
	var conditions = get_state("reward_conditions", {})
	if reward_id not in conditions:
		return true
	return conditions[reward_id].is_empty()

func get_claimed_reward_count() -> int:
	return get_state("claimed_rewards", []).size()

func get_total_rewards_value() -> float:
	var claimed_ids = get_state("claimed_rewards", [])
	var total = 0.0
	for reward in reward_pool:
		if reward.id in claimed_ids:
			total += reward.value * get_reward_multiplier()
	return total

func get_reward_statistics() -> Dictionary:
	return {
		"total_rewards_defined": reward_pool.size(),
		"pending_count": get_reward_count(),
		"claimed_count": get_claimed_reward_count(),
		"total_value_claimed": get_total_rewards_value(),
		"reward_events_logged": get_state("reward_history", []).size(),
		"current_multiplier": get_reward_multiplier(),
		"conditions_registered": get_state("reward_conditions", {}).size()
	}
