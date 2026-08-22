extends Node

# ─── Dialogue System ──────────────────────────────────────────────────────────
# All Valmiki Ramayana dialogue, narration, and choices

signal dialogue_started(dialogue_id: String)
signal dialogue_line(speaker: String, text: String, portrait: String)
signal dialogue_choice(choices: Array)
signal dialogue_ended(dialogue_id: String)

var _current_dialogue: String = ""
var _current_line: int = 0
var _is_playing: bool = false
var _lines: Array = []

const DIALOGUES: Dictionary = {
	# ── Chapter 1 ──────────────────────────────────────────────────────────────
	"rama_first_meeting": [
		{"speaker": "NARRATOR", "text": "At the foot of Rishyamukha mountain, Hanuman spots two magnificent warriors dressed as ascetics — their divine form impossible to miss.", "portrait": "narrator"},
		{"speaker": "SUGRIVA", "text": "Hanuman! Go to those two warriors. Find out who they are and what brings them here.", "portrait": "sugriva"},
		{"speaker": "HANUMAN", "text": "As you command, Sugriva. I shall approach them.", "portrait": "hanuman"},
		{"speaker": "HANUMAN", "text": "O noble ones! Your form speaks of royalty yet your dress speaks of hermits. Who are you, and what brings you to these forests?", "portrait": "hanuman"},
		{"speaker": "RAMA", "text": "I am Rama, son of Dasharatha, King of Ayodhya. This is my brother Lakshmana. We search for my wife Sita, abducted by the demon Ravana.", "portrait": "rama"},
		{"speaker": "LAKSHMANA", "text": "We were told to seek Sugriva, the Vanara king, who may help us.", "portrait": "lakshmana"},
		{"speaker": "HANUMAN", "text": "Then the stars themselves have aligned! Sugriva is my lord. I am Hanuman, son of Vayu — and I shall ensure this alliance is made.", "portrait": "hanuman"},
		{"speaker": "NARRATOR", "text": "Hanuman, in his wisdom, recognizes the divinity in Rama. A great friendship is about to be born.", "portrait": "narrator"}
	],
	"vali_context": [
		{"speaker": "SUGRIVA", "text": "Rama, my brother Vali wrongfully exiled me and took my wife. I ask for your help.", "portrait": "sugriva"},
		{"speaker": "RAMA", "text": "Tell me more. Why did Vali exile you?", "portrait": "rama"},
		{"speaker": "SUGRIVA", "text": "A demon lured Vali into a cave. I sealed it, thinking him dead. When he emerged alive — furious — he blamed me for treachery.", "portrait": "sugriva"},
		{"speaker": "HANUMAN", "text": "Sugriva speaks truth. I was there. Vali is mighty but his anger blinds his justice.", "portrait": "hanuman"},
		{"speaker": "RAMA", "text": "I give you my word, Sugriva. Vali shall be dealt with. In return, help me find Sita.", "portrait": "rama"}
	],
	"dundhubi_task": [
		{"speaker": "SUGRIVA", "text": "Rama, to test your strength — can you kick this mountain of bones? It is the carcass of Dundhubi, the demon Vali slew.", "portrait": "sugriva"},
		{"speaker": "NARRATOR", "text": "The bones form a mountain range that even elephants cannot move.", "portrait": "narrator"},
		{"speaker": "HANUMAN", "text": "Watch closely, Sugriva.", "portrait": "hanuman"},
		{"speaker": "NARRATOR", "text": "Rama kicks the bones with one foot — they fly across the horizon.", "portrait": "narrator"},
		{"speaker": "SUGRIVA", "text": "Extraordinary! Then pierce these seven sala trees with a single arrow.", "portrait": "sugriva"}
	],
	# ── Chapter 2 ──────────────────────────────────────────────────────────────
	"great_leap_narration": [
		{"speaker": "NARRATOR", "text": "The month of search ends. The Vanaras reach the southern shore. The ocean stretches endlessly. Lanka lies beyond.", "portrait": "narrator"},
		{"speaker": "JAMBAVAN", "text": "Who among us can leap one hundred yojanas across this ocean?", "portrait": "jambavan"},
		{"speaker": "ANGADA", "text": "I could leap there, but I am not sure I can return.", "portrait": "angada"},
		{"speaker": "JAMBAVAN", "text": "There is one who can. Hanuman — you have forgotten your own power. You are the son of Vayu himself!", "portrait": "jambavan"},
		{"speaker": "HANUMAN", "text": "You remind me of what I had forgotten. My power was bounded in childhood by a sage's curse. I remember it now.", "portrait": "hanuman"},
		{"speaker": "HANUMAN", "text": "I shall cross this ocean! I shall find Sita! JAI SHRI RAM!", "portrait": "hanuman"},
		{"speaker": "NARRATOR", "text": "Hanuman grows to the size of a mountain. The earth shakes. The ocean trembles. He crouches — and leaps.", "portrait": "narrator"}
	],
	"mainaka_meeting": [
		{"speaker": "MAINAKA", "text": "Hanuman! I am Mainaka, mountain of the sea. Rest upon me — you have far to go.", "portrait": "mainaka"},
		{"speaker": "HANUMAN", "text": "I thank you, friend Mainaka. But I have pledged not to rest until I find Sita. I must press on.", "portrait": "hanuman"},
		{"speaker": "MAINAKA", "text": "Then go with the blessings of the ocean. May your mission succeed!", "portrait": "mainaka"}
	],
	"surasa_challenge": [
		{"speaker": "SURASA", "text": "I am Surasa! The gods have decreed that nothing passes me without entering my mouth. Enter, Hanuman!", "portrait": "surasa"},
		{"speaker": "HANUMAN", "text": "Very well. Open your mouth to receive me.", "portrait": "hanuman"},
		{"speaker": "NARRATOR", "text": "Surasa opens her mouth ten yojanas wide. Hanuman grows twenty yojanas tall. She opens thirty — he grows forty. Then in a flash, he shrinks to thumb-size, enters her mouth, and exits before she closes it.", "portrait": "narrator"},
		{"speaker": "SURASA", "text": "Remarkable! You have honored the decree by entering my mouth — and your wit has freed you. Go, mighty one, you have my blessing.", "portrait": "surasa"}
	],
	"simhika_encounter": [
		{"speaker": "NARRATOR", "text": "A shadow falls across Hanuman mid-flight. Something is pulling him down from below the waves.", "portrait": "narrator"},
		{"speaker": "SIMHIKA", "text": "You are my prey! I catch shadows — your shadow is mine!", "portrait": "simhika"},
		{"speaker": "HANUMAN", "text": "You are Simhika — the one who swallows by shadow. But today, you face Hanuman!", "portrait": "hanuman"}
	],
	# ── Chapter 3 ──────────────────────────────────────────────────────────────
	"lanka_entry": [
		{"speaker": "NARRATOR", "text": "Lanka blazes with gold. Its towers pierce the sky. Ravana's kingdom — the most magnificent and terrible city ever built.", "portrait": "narrator"},
		{"speaker": "HANUMAN", "text": "I must enter unseen. Shrinking to the size of a cat, I will search every corner until I find Mother Sita.", "portrait": "hanuman"},
		{"speaker": "LANKINI", "text": "HALT! I am Lankini, guardian of Lanka's gates. Nothing enters without my permission!", "portrait": "lankini"},
		{"speaker": "HANUMAN", "text": "Forgive me.", "portrait": "hanuman"},
		{"speaker": "NARRATOR", "text": "A single blow sends Lankini stumbling. An old prophecy rings in her ears: 'When a monkey bests you, Lanka's end is near.'", "portrait": "narrator"},
		{"speaker": "LANKINI", "text": "Enter... Lanka's fate is sealed.", "portrait": "lankini"}
	],
	"sita_found": [
		{"speaker": "NARRATOR", "text": "After searching every palace, every tower, every garden — Hanuman finds the Ashoka Vatika. And there, beneath an Ashoka tree, surrounded by demonesses — Sita.", "portrait": "narrator"},
		{"speaker": "HANUMAN", "text": "She is thin, pale with grief, her ornaments gone. But her divinity shines undimmed. This must be her.", "portrait": "hanuman"},
		{"speaker": "RAVANA", "text": "Beautiful Sita! Abandon this foolish devotion to that exile Rama. Become Queen of Lanka! I offer you the world.", "portrait": "ravana"},
		{"speaker": "SITA", "text": "Place a blade of grass between us — that distance is the distance between you and Rama. Do not speak Rama's name with your unworthy tongue.", "portrait": "sita"},
		{"speaker": "NARRATOR", "text": "Ravana leaves in fury. The demonesses threaten Sita. She weeps — but does not yield.", "portrait": "narrator"}
	],
	"ring_delivery": [
		{"speaker": "HANUMAN", "text": "(Speaking from the treetop softly) Mother Sita — I am Hanuman, servant of Lord Rama. He sends you this.", "portrait": "hanuman"},
		{"speaker": "SITA", "text": "Who speaks? Another trick of Ravana's?", "portrait": "sita"},
		{"speaker": "HANUMAN", "text": "No, Mother. Here — Rama's signet ring. He has not forgotten you. He is coming.", "portrait": "hanuman"},
		{"speaker": "SITA", "text": "This ring... Rama's ring... He remembered.", "portrait": "sita"},
		{"speaker": "SITA", "text": "Tell Rama — I have one month's strength left. After that, Ravana's threats will mean my end.", "portrait": "sita"},
		{"speaker": "HANUMAN", "text": "I shall carry your message as I carry your hope. Take courage, Mother.", "portrait": "hanuman"},
		{"speaker": "SITA", "text": "Take this Chudamani — my hair ornament. Give it to Rama so he knows you truly met me.", "portrait": "sita"}
	],
	# ── Chapter 4 ──────────────────────────────────────────────────────────────
	"vatika_destruction": [
		{"speaker": "HANUMAN", "text": "I have found Sita. I have delivered the ring. But I must also know Lanka's strength — and I must make Ravana know I was here.", "portrait": "hanuman"},
		{"speaker": "NARRATOR", "text": "Hanuman begins eating the fruits of Ashoka Vatika. Then he pulls up trees. Guards rush in.", "portrait": "narrator"},
		{"speaker": "HANUMAN", "text": "Come then! Face the servant of Rama!", "portrait": "hanuman"}
	],
	"ravana_court": [
		{"speaker": "RAVANA", "text": "So. A monkey stands in my court with his tail on fire. Amusing.", "portrait": "ravana"},
		{"speaker": "HANUMAN", "text": "Not a monkey. A messenger. Lord Rama demands you return Sita immediately. Return her — and your life and Lanka are spared.", "portrait": "hanuman"},
		{"speaker": "RAVANA", "text": "Kill him!", "portrait": "ravana"},
		{"speaker": "VIBHISHANA", "text": "Brother — one does not kill a messenger. It is against dharma.", "portrait": "vibhishana"},
		{"speaker": "RAVANA", "text": "Fine. Set his tail on fire instead.", "portrait": "ravana"},
		{"speaker": "HANUMAN", "text": "(Internal) They think fire will hurt the son of Agni's friend? Let them try.", "portrait": "hanuman"},
		{"speaker": "NARRATOR", "text": "The soldiers wrap Hanuman's long tail in cloth and oil and light it. Hanuman lets them. He has a plan.", "portrait": "narrator"}
	],
	"lanka_burning": [
		{"speaker": "NARRATOR", "text": "With his tail ablaze, Hanuman leaps free of his bonds. He bounds from rooftop to rooftop — palace to palace — tower to tower.", "portrait": "narrator"},
		{"speaker": "HANUMAN", "text": "Lanka! Know that this fire is a message from Rama!", "portrait": "hanuman"},
		{"speaker": "NARRATOR", "text": "The golden city burns. Only Vibhishana's house and Sita's Ashoka Vatika are spared. Lanka weeps in fire.", "portrait": "narrator"},
		{"speaker": "HANUMAN", "text": "Now — back to Lord Rama.", "portrait": "hanuman"}
	],
	# ── Chapter 5 ──────────────────────────────────────────────────────────────
	"news_to_rama": [
		{"speaker": "HANUMAN", "text": "Jay Shri Ram! I have found Mother Sita!", "portrait": "hanuman"},
		{"speaker": "RAMA", "text": "Hanuman... you found her? She is alive?", "portrait": "rama"},
		{"speaker": "HANUMAN", "text": "Alive, Lord — imprisoned but unbroken. She sends you this Chudamani.", "portrait": "hanuman"},
		{"speaker": "NARRATOR", "text": "Rama holds the hair ornament. Tears fall from his eyes for the first time in the long exile.", "portrait": "narrator"},
		{"speaker": "RAMA", "text": "What can I give you, Hanuman? You have given me back my life.", "portrait": "rama"},
		{"speaker": "HANUMAN", "text": "Only your grace, Lord. Only your grace.", "portrait": "hanuman"}
	],
	"ram_setu": [
		{"speaker": "VIBHISHANA", "text": "Rama — I am Ravana's brother. But his path is adharma. I seek your refuge.", "portrait": "vibhishana"},
		{"speaker": "RAMA", "text": "Whoever comes to me seeking refuge shall never be turned away. Rise, Vibhishana.", "portrait": "rama"},
		{"speaker": "NARRATOR", "text": "Rama approaches the ocean with his bow. The ocean refuses to part. He raises his arrow — the ocean trembles and appears before him.", "portrait": "narrator"},
		{"speaker": "SAMUDRA", "text": "Lord! I cannot defy my nature and dry up. But the engineer Nala can build a bridge across me. The stones engraved with Rama's name will float.", "portrait": "samudra"},
		{"speaker": "NARRATOR", "text": "The great bridge — Ram Setu — is built in five days. A million Vanaras march to Lanka.", "portrait": "narrator"}
	],
	# ── Chapter 6 ──────────────────────────────────────────────────────────────
	"lakshmana_falls": [
		{"speaker": "NARRATOR", "text": "Indrajit, Ravana's son, uses the Shakti weapon — a divine spear that cannot be blocked. It strikes Lakshmana.", "portrait": "narrator"},
		{"speaker": "RAMA", "text": "LAKSHMANA!", "portrait": "rama"},
		{"speaker": "SUSENA", "text": "He lives — but barely. Only the Sanjeevani herb from Mount Dronagiri in the Himalayas can save him. Before sunrise.", "portrait": "susena"},
		{"speaker": "HANUMAN", "text": "I will go. Tell me what the herb looks like.", "portrait": "hanuman"},
		{"speaker": "SUSENA", "text": "It glows like moonlight on the mountain's northern face.", "portrait": "susena"},
		{"speaker": "HANUMAN", "text": "Then there is no time to waste. JAI SHRI RAM!", "portrait": "hanuman"},
		{"speaker": "NARRATOR", "text": "Hanuman flies north at the speed of wind. Kalayavana tries to block him. Demons attack mid-flight. None can stop him.", "portrait": "narrator"}
	],
	"sanjeevani_quest": [
		{"speaker": "NARRATOR", "text": "Hanuman reaches the Himalayas. Mount Dronagiri. But the herbs are hidden — their glow masked by the demon Kalanemi's magic.", "portrait": "narrator"},
		{"speaker": "HANUMAN", "text": "I cannot find the specific herb. But I will not fail Lakshmana.", "portrait": "hanuman"},
		{"speaker": "NARRATOR", "text": "Hanuman makes a decision. He lifts the entire mountain — all of Mount Dronagiri — and carries it back to Lanka.", "portrait": "narrator"},
		{"speaker": "SUSENA", "text": "The mountain itself! Brilliant! I can find the herb now.", "portrait": "susena"},
		{"speaker": "NARRATOR", "text": "Susena finds the Sanjeevani. Lakshmana breathes. His eyes open. The army roars.", "portrait": "narrator"}
	],
	"ravana_final": [
		{"speaker": "NARRATOR", "text": "Head after head falls. Rama cuts them faster than they grow back. The battle rages. Then Agastya appears.", "portrait": "narrator"},
		{"speaker": "AGASTYA", "text": "Rama! Use the Aditya Hridayam — the hymn of the sun. It will destroy Ravana.", "portrait": "agastya"},
		{"speaker": "NARRATOR", "text": "Rama recites the hymn. His arrow — infused with cosmic power — strikes Ravana's navel, where his immortality resides.", "portrait": "narrator"},
		{"speaker": "RAVANA", "text": "...impossible.", "portrait": "ravana"},
		{"speaker": "NARRATOR", "text": "Ravana falls. The sky clears. Flowers rain from heaven. Lanka is free.", "portrait": "narrator"}
	],
	# ── Chapter 7 ──────────────────────────────────────────────────────────────
	"sita_freed": [
		{"speaker": "RAMA", "text": "Sita...", "portrait": "rama"},
		{"speaker": "SITA", "text": "Rama...", "portrait": "sita"},
		{"speaker": "NARRATOR", "text": "After months of separation, after oceans crossed and wars won, Rama and Sita stand before each other. The world holds its breath.", "portrait": "narrator"}
	],
	"ayodhya_return": [
		{"speaker": "NARRATOR", "text": "The Pushpaka Vimana rises. Lanka shrinks below. The ocean glitters. India appears on the horizon.", "portrait": "narrator"},
		{"speaker": "RAMA", "text": "Hanuman — look. Ayodhya. Home.", "portrait": "rama"},
		{"speaker": "HANUMAN", "text": "Fourteen years of exile end today, Lord.", "portrait": "hanuman"},
		{"speaker": "NARRATOR", "text": "Ayodhya erupts in celebration. Lamps are lit in every window. The people chant RAMA RAMA RAMA. The night becomes day.", "portrait": "narrator"},
		{"speaker": "RAMA", "text": "This victory belongs not to me — but to Hanuman, who crossed the impossible ocean, to Sugriva's army, and to the righteousness of dharma.", "portrait": "rama"}
	]
}

func _ready() -> void:
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if not _is_playing:
		return
	var is_click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if event.is_action_pressed("interact") or is_click:
		advance()
		get_viewport().set_input_as_handled()

func start_dialogue(dialogue_id: String) -> void:
	if not DIALOGUES.has(dialogue_id):
		return
	_current_dialogue = dialogue_id
	_current_line = 0
	_is_playing = true
	_lines = DIALOGUES[dialogue_id]
	GameManager.set_state(GameManager.GameState.DIALOGUE)
	dialogue_started.emit(dialogue_id)
	_show_current_line()

func advance() -> void:
	if not _is_playing:
		return
	_current_line += 1
	if _current_line >= _lines.size():
		_end_dialogue()
	else:
		_show_current_line()

func _show_current_line() -> void:
	var line: Dictionary = _lines[_current_line]
	dialogue_line.emit(
		line.get("speaker", ""),
		line.get("text", ""),
		line.get("portrait", "")
	)
	AudioManager.play_sfx("dialogue_beep")

func _end_dialogue() -> void:
	_is_playing = false
	var id := _current_dialogue
	_current_dialogue = ""
	GameManager.set_state(GameManager.GameState.PLAYING)
	dialogue_ended.emit(id)

func is_playing() -> bool:
	return _is_playing
