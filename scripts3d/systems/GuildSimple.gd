extends BaseSystemSimple

class_name GuildSimple

class Guild:
	var id: String
	var name: String
	var description: String
	var level: int = 1
	var treasury: float = 0.0
	var members: int = 1
	var max_members: int = 50
	var reputation: float = 0.0
	var prestige: float = 0.0
	var perks: Array[String] = []
	var member_ranks: Dictionary = {}
	var storage_capacity: int = 50
	var storage_items: Dictionary = {}
	var daily_quests: Array[String] = []
	var hall_upgrades: Dictionary = {"forge": 0, "library": 0, "training": 0}
	var rival_guilds: Array[String] = []
	var allied_guilds: Array[String] = []
	func _init(p_id: String, p_name: String, p_desc: String) -> void:
		id = p_id
		name = p_name
		description = p_desc
		_initialize_perks()

	func _initialize_perks() -> void:
		perks = ["exp_boost_5"]
		match id:
			"merchants":
				perks = ["trade_discount_10", "vault_unlock"]
			"hunters":
				perks = ["hunting_bonus_15", "mount_exp_boost"]
			"mages":
				perks = ["mana_regen_10", "spell_cooldown_reduction"]
			"rangers":
				perks = ["archery_bonus_15", "tracking_improved"]

var guilds: Array[Guild] = []

signal guild_created(guild: Guild)
signal guild_joined(guild: Guild)
signal guild_level_up(guild: Guild)

func _ready() -> void:
	set_state("player_guild_id", "")
	set_state("member_contributions", {})
	set_state("member_roles", {})
	set_state("guild_wars", [])
	set_state("guild_events", [])
	_initialize_guilds()

func _initialize_guilds() -> void:
	guilds = [
		Guild.new("merchants", "Merchants Guild", "Trade and commerce"),
		Guild.new("hunters", "Hunters Guild", "Hunting and combat"),
		Guild.new("mages", "Mage Society", "Magic and knowledge"),
		Guild.new("rangers", "Rangers Order", "Survival and archery")
	]

func create_guild(guild_name: String, guild_desc: String) -> Guild:
	var guild = Guild.new("guild_%d" % guilds.size(), guild_name, guild_desc)
	guilds.append(guild)
	guild_created.emit(guild)
	emit_event("guild_created", guild_name)
	return guild

func join_guild(guild_id: String) -> bool:
	for guild in guilds:
		if guild.id == guild_id and guild.members < guild.max_members:
			guild.members += 1
			set_state("player_guild_id", guild_id)
			var roles = get_state("member_roles", {})
			roles["player"] = "member"
			set_state("member_roles", roles)
			var contribs = get_state("member_contributions", {})
			contribs["player"] = 0.0
			set_state("member_contributions", contribs)
			guild_joined.emit(guild)
			emit_event("joined", guild_id)
			return true
	return false

func add_member_contribution(member_id: String, amount: float) -> void:
	var guild_id = get_state("player_guild_id", "")
	for guild in guilds:
		if guild.id == guild_id:
			var contribs = get_state("member_contributions", {})
			contribs[member_id] = contribs.get(member_id, 0.0) + amount
			set_state("member_contributions", contribs)
			guild.reputation += amount * 0.1
			emit_event("contribution_added", {"member": member_id, "amount": amount})

func add_to_treasury(amount: float) -> void:
	var guild_id = get_state("player_guild_id", "")
	for guild in guilds:
		if guild.id == guild_id:
			guild.treasury += amount
			guild.prestige += amount * 0.01
			if guild.treasury >= guild.level * 1000:
				_level_up_guild(guild)

func _level_up_guild(guild: Guild) -> void:
	guild.level += 1
	guild.max_members += 10
	guild.storage_capacity += 25
	guild.treasury -= guild.level * 1000
	guild_level_up.emit(guild)
	emit_event("level_up", guild.id)

func upgrade_hall(upgrade_type: String, cost: float) -> bool:
	var guild_id = get_state("player_guild_id", "")
	for guild in guilds:
		if guild.id == guild_id and upgrade_type in guild.hall_upgrades:
			if guild.treasury >= cost:
				guild.treasury -= cost
				guild.hall_upgrades[upgrade_type] += 1
				emit_event("hall_upgraded", {"upgrade": upgrade_type, "level": guild.hall_upgrades[upgrade_type]})
				return true
	return false

func add_to_storage(item_name: String, quantity: int) -> bool:
	var guild_id = get_state("player_guild_id", "")
	for guild in guilds:
		if guild.id == guild_id:
			var current_items = 0
			for item in guild.storage_items.values():
				current_items += item
			if current_items + quantity <= guild.storage_capacity:
				guild.storage_items[item_name] = guild.storage_items.get(item_name, 0) + quantity
				emit_event("storage_added", {"item": item_name, "quantity": quantity})
				return true
	return false

func declare_war(rival_guild_id: String) -> void:
	var guild_id = get_state("player_guild_id", "")
	for guild in guilds:
		if guild.id == guild_id and rival_guild_id not in guild.rival_guilds:
			guild.rival_guilds.append(rival_guild_id)
			emit_event("war_declared", rival_guild_id)

func create_alliance(ally_guild_id: String) -> void:
	var guild_id = get_state("player_guild_id", "")
	for guild in guilds:
		if guild.id == guild_id and ally_guild_id not in guild.allied_guilds:
			guild.allied_guilds.append(ally_guild_id)
			emit_event("alliance_formed", ally_guild_id)

func get_guild(guild_id: String) -> Guild:
	for guild in guilds:
		if guild.id == guild_id:
			return guild
	return null

func get_all_guilds() -> Array[Guild]:
	return guilds

func get_player_guild() -> Guild:
	var guild_id = get_state("player_guild_id", "")
	for guild in guilds:
		if guild.id == guild_id:
			return guild
	return null

func get_guild_perks() -> Array[String]:
	var guild = get_player_guild()
	return guild.perks if guild else []

func get_guild_storage() -> Dictionary:
	var guild = get_player_guild()
	return guild.storage_items if guild else {}

func get_guild_info_text() -> String:
	var guild = get_player_guild()
	if not guild:
		return "Guild: None"
	var storage_used = 0
	for count in guild.storage_items.values():
		storage_used += count
	return "%s | Level: %d | Reputation: %.0f\nMembers: %d/%d | Treasury: %.0f\nStorage: %d/%d" % [guild.name, guild.level, guild.reputation, guild.members, guild.max_members, guild.treasury, storage_used, guild.storage_capacity]
