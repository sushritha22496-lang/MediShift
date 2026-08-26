extends Node

class_name AnimationStateMachine

var anim_player: AnimationPlayer
var current_anim: String = ""
var previous_anim: String = ""

var state_anims: Dictionary = {
	"idle": "idle",
	"walk": "walk",
	"run": "run",
	"jump": "jump",
	"attack": "attack",
	"hurt": "hurt",
	"celebrate": "celebration"
}

signal animation_started(anim: String)
signal animation_finished(anim: String)

func _ready() -> void:
	anim_player = get_parent().get_node_or_null("AnimationPlayer")
	if anim_player:
		anim_player.animation_finished.connect(_on_animation_finished)

func play(state: String, force: bool = false) -> bool:
	if not anim_player:
		return false

	var anim = state_anims.get(state, state)

	if anim == current_anim and not force:
		return false

	if anim_player.has_animation(anim):
		previous_anim = current_anim
		current_anim = anim
		anim_player.play(anim)
		animation_started.emit(anim)
		return true

	return false

func _on_animation_finished(anim: String) -> void:
	animation_finished.emit(anim)

func get_current() -> String:
	return current_anim

func is_playing(anim: String) -> bool:
	return current_anim == anim and anim_player and anim_player.is_playing()
