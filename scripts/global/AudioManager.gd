extends Node

var _bgm_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_pool_size: int = 8
var _sfx_index: int = 0

var bgm_volume: float = 0.8
var sfx_volume: float = 1.0

const BGM_TRACKS: Dictionary = {
	"menu":        "res://assets/audio/bgm/menu.ogg",
	"kishkindha":  "res://assets/audio/bgm/kishkindha.ogg",
	"leap":        "res://assets/audio/bgm/leap.ogg",
	"lanka_night": "res://assets/audio/bgm/lanka_stealth.ogg",
	"rampage":     "res://assets/audio/bgm/rampage.ogg",
	"war":         "res://assets/audio/bgm/war.ogg",
	"boss":        "res://assets/audio/bgm/boss.ogg",
	"ravana_boss": "res://assets/audio/bgm/ravana_boss.ogg",
	"victory":     "res://assets/audio/bgm/victory.ogg",
	"game_over":   "res://assets/audio/bgm/game_over.ogg"
}

const SFX_MAP: Dictionary = {
	"gada_swing":      "res://assets/audio/sfx/gada_swing.ogg",
	"gada_hit":        "res://assets/audio/sfx/gada_hit.ogg",
	"gada_heavy":      "res://assets/audio/sfx/gada_heavy.ogg",
	"jump":            "res://assets/audio/sfx/jump.ogg",
	"double_jump":     "res://assets/audio/sfx/double_jump.ogg",
	"land":            "res://assets/audio/sfx/land.ogg",
	"fly_start":       "res://assets/audio/sfx/fly_start.ogg",
	"fly_loop":        "res://assets/audio/sfx/fly_loop.ogg",
	"dash":            "res://assets/audio/sfx/dash.ogg",
	"roar":            "res://assets/audio/sfx/hanuman_roar.ogg",
	"tail_fire":       "res://assets/audio/sfx/tail_fire.ogg",
	"mahima":          "res://assets/audio/sfx/mahima_grow.ogg",
	"anima":           "res://assets/audio/sfx/anima_shrink.ogg",
	"enemy_hit":       "res://assets/audio/sfx/enemy_hit.ogg",
	"enemy_death":     "res://assets/audio/sfx/enemy_death.ogg",
	"boss_roar":       "res://assets/audio/sfx/boss_roar.ogg",
	"power_unlock":    "res://assets/audio/sfx/power_unlock.ogg",
	"collect":         "res://assets/audio/sfx/collect.ogg",
	"dialogue_beep":   "res://assets/audio/sfx/dialogue.ogg",
	"cheat_activate":  "res://assets/audio/sfx/cheat.ogg",
	"explosion":       "res://assets/audio/sfx/explosion.ogg",
	"sanjeevani":      "res://assets/audio/sfx/sanjeevani.ogg"
}

func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "BGM"
	add_child(_bgm_player)
	for i in _sfx_pool_size:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)

func play_bgm(track_name: String, fade_in: float = 1.0) -> void:
	if not BGM_TRACKS.has(track_name):
		return
	var path: String = BGM_TRACKS[track_name]
	if not ResourceLoader.exists(path):
		return
	var stream = load(path)
	if not stream:
		return
	_bgm_player.stream = stream
	_bgm_player.volume_db = linear_to_db(0.0)
	_bgm_player.play()
	var tween := create_tween()
	tween.tween_property(_bgm_player, "volume_db", linear_to_db(bgm_volume), fade_in)

func stop_bgm(fade_out: float = 1.0) -> void:
	var tween := create_tween()
	tween.tween_property(_bgm_player, "volume_db", linear_to_db(0.0), fade_out)
	tween.tween_callback(_bgm_player.stop)

func play_sfx(sfx_name: String, volume_scale: float = 1.0) -> void:
	if not SFX_MAP.has(sfx_name):
		return
	var path: String = SFX_MAP[sfx_name]
	if not ResourceLoader.exists(path):
		return
	var stream = load(path)
	if not stream:
		return
	var player := _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_pool_size
	player.stream = stream
	player.volume_db = linear_to_db(sfx_volume * volume_scale)
	player.play()

func set_bgm_volume(vol: float) -> void:
	bgm_volume = clampf(vol, 0.0, 1.0)
	_bgm_player.volume_db = linear_to_db(bgm_volume)

func set_sfx_volume(vol: float) -> void:
	sfx_volume = clampf(vol, 0.0, 1.0)
