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
	func _init(p_id: String, p_name: String, p_desc: String) -> void:
		id = p_id
		name = p_name
		description = p_desc

var guilds: Array[Guild] = []

signal guild_created(guild: Guild)
signal guild_joined(guild: Guild)
signal guild_level_up(guild: Guild)

func _ready() -> void:
	set_state("player_guild_id", "")
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
			guild_joined.emit(guild)
			emit_event("joined", guild_id)
			return true
	return false

func add_to_treasury(amount: float) -> void:
	var guild_id = get_state("player_guild_id", "")
	for guild in guilds:
		if guild.id == guild_id:
			guild.treasury += amount
			if guild.treasury >= guild.level * 1000:
				_level_up_guild(guild)

func _level_up_guild(guild: Guild) -> void:
	guild.level += 1
	guild.max_members += 10
	guild_level_up.emit(guild)
	emit_event("level_up", guild.id)

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

func get_guild_info_text() -> String:
	var guild = get_player_guild()
	if not guild:
		return "Guild: None"
	return "%s\nLevel: %d | Members: %d/%d\nTreasury: %.0f gold\n" % [guild.name, guild.level, guild.members, guild.max_members, guild.treasury]
