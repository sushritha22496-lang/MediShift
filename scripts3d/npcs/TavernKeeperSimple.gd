extends NPCSimple

class_name TavernKeeperSimple

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

signal drink_sold(drink: String, price: float)
signal rumor_shared(rumor: String)

func _ready() -> void:
	npc_name = "Tavern Keeper"
	add_to_group("npcs")
	walk_speed = 0.0
	run_speed = 0.0
	if anim_player and anim_player.has_animation("idle"):
		anim_player.play("idle")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	_play_anim("idle")
	velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)
	move_and_slide()

func sell_drink(player: Node3D, drink_name: String) -> bool:
	if not drink_name in drinks:
		return false
	var drink = drinks[drink_name]
	if drink["stock"] <= 0:
		dialogue.emit("Sorry, we're out of %s!" % drink_name)
		return false
	var price = drink["price"]
	drink["stock"] -= 1
	drink_sold.emit(drink_name, price)
	dialogue.emit("That'll be %d gold!" % price)
	return true

func share_rumor(player: Node3D) -> void:
	if rumors.is_empty():
		return
	var rumor = rumors[randi() % rumors.size()]
	rumor_shared.emit(rumor)
	dialogue.emit("Psst... %s" % rumor)

func get_tavern_text() -> String:
	var text = "🍺 %s\n" % npc_name
	for drink_name in drinks:
		var drink = drinks[drink_name]
		text += "%s - %d gold (Stock: %d)\n" % [drink_name, drink["price"], drink["stock"]]
	return text

func interact(player: Node3D) -> void:
	dialogue.emit("Welcome to my tavern!")
