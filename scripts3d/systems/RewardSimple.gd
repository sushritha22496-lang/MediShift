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
			reward_claimed.emit(reward_id)
			emit_event("reward_claimed", reward_id)
			return reward
	return null

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
