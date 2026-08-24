extends Node

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
var player_guild: Guild = null

signal guild_created(guild: Guild)
signal guild_joined(guild: Guild)
signal guild_level_up(guild: Guild)
signal guild_mission_completed(guild: Guild)

func _ready() -> void:
	_initialize_guilds()

func _initialize_guilds() -> void:
	var g1 = Guild.new("merchants", "Merchants Guild", "Trade and commerce")
	var g2 = Guild.new("hunters", "Hunters Guild", "Hunting and combat")
	var g3 = Guild.new("mages", "Mage Society", "Magic and knowledge")
	var g4 = Guild.new("rangers", "Rangers Order", "Survival and archery")

	guilds = [g1, g2, g3, g4]

func create_guild(guild_name: String, guild_desc: String) -> Guild:
	var guild = Guild.new("guild_%d" % guilds.size(), guild_name, guild_desc)
	guilds.append(guild)
	guild_created.emit(guild)
	print("Guild created: %s" % guild_name)
	return guild

func join_guild(guild_id: String) -> bool:
	for guild in guilds:
		if guild.id == guild_id:
			if guild.members < guild.max_members:
				guild.members += 1
				player_guild = guild
				guild_joined.emit(guild)
				print("Joined guild: %s" % guild.name)
				return true
	return false

func add_to_treasury(amount: float) -> void:
	if player_guild:
		player_guild.treasury += amount
		if player_guild.treasury >= player_guild.level * 1000:
			_level_up_guild()

func _level_up_guild() -> void:
	if player_guild:
		player_guild.level += 1
		player_guild.max_members += 10
		guild_level_up.emit(player_guild)
		print("🏆 %s reached level %d!" % [player_guild.name, player_guild.level])

func get_guild(guild_id: String) -> Guild:
	for guild in guilds:
		if guild.id == guild_id:
			return guild
	return null

func get_all_guilds() -> Array[Guild]:
	return guilds

func get_player_guild() -> Guild:
	return player_guild

func get_guild_info_text() -> String:
	if not player_guild:
		return "Guild: None"
	var text = "%s\n" % player_guild.name
	text += "Level: %d | Members: %d/%d\n" % [player_guild.level, player_guild.members, player_guild.max_members]
	text += "Treasury: %.0f gold\n" % player_guild.treasury
	return text
