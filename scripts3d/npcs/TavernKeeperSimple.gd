extends Node3D

class_name TavernKeeperSimple

@export var tavern_name: String = "Tavern"
@export var tavern_location: Vector3 = Vector3.ZERO

var drinks: Dictionary = {
	"Ale": {"price": 10, "stock": 50},
	"Wine": {"price": 20, "stock": 30},
	"Mead": {"price": 15, "stock": 40}
}

var rumors: Array[String] = [
	"I heard bandits in the north!",
	"A powerful artifact was found in the mountains",
	"The temple needs help from adventurers",
	"Strange creatures appear at night"
]

@onready var model: Node3D = $Model
@onready var anim_player: AnimationPlayer = $Model/AnimationPlayer

signal tavern_keeper_dialogue(text: String)
signal drink_sold(drink: String, price: float)
signal rumor_shared(rumor: String)

func _ready() -> void:
	add_to_group("npcs")
	tavern_location = global_position

	if anim_player and anim_player.has_animation("idle"):
		anim_player.play("idle")

func sell_drink(player: Node3D, drink_name: String) -> bool:
	if not drink_name in drinks:
		return false

	var drink = drinks[drink_name]
	if drink["stock"] <= 0:
		tavern_keeper_dialogue.emit("Sorry, we're out of %s!" % drink_name)
		return false

	var price = drink["price"]
	drink["stock"] -= 1
	drink_sold.emit(drink_name, price)
	tavern_keeper_dialogue.emit("That'll be %d gold!" % price)
	return true

func share_rumor(player: Node3D) -> void:
	if rumors.is_empty():
		return

	var rumor = rumors[randi() % rumors.size()]
	rumor_shared.emit(rumor)
	tavern_keeper_dialogue.emit("Psst... %s" % rumor)

func get_tavern_text() -> String:
	var text = "🍺 %s\n" % tavern_name
	for drink_name in drinks:
		var drink = drinks[drink_name]
		text += "%s - %d gold (Stock: %d)\n" % [drink_name, drink["price"], drink["stock"]]
	return text

func interact(player: Node3D) -> void:
	tavern_keeper_dialogue.emit("Welcome to %s!" % tavern_name)
