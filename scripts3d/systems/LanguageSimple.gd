extends BaseSystemSimple

class_name LanguageSimple

var translations: Dictionary = {}

signal language_changed(language_code: String)

func _ready() -> void:
	set_state("current_language", "en")
	_initialize_translations()

func _initialize_translations() -> void:
	translations["en"] = {
		"welcome": "Welcome to Ramayana Quest",
		"start_game": "Start Game",
		"continue": "Continue",
		"settings": "Settings",
		"quit": "Quit Game",
		"inventory": "Inventory",
		"quests": "Quests",
		"skills": "Skills",
		"map": "Map",
		"health": "Health",
		"mana": "Mana",
		"level": "Level",
		"experience": "Experience"
	}

	translations["es"] = {
		"welcome": "Bienvenido a la Búsqueda de Ramayana",
		"start_game": "Comenzar Juego",
		"continue": "Continuar",
		"settings": "Configuración",
		"quit": "Salir",
		"inventory": "Inventario",
		"quests": "Misiones",
		"skills": "Habilidades",
		"map": "Mapa",
		"health": "Salud",
		"mana": "Maná",
		"level": "Nivel",
		"experience": "Experiencia"
	}

	translations["fr"] = {
		"welcome": "Bienvenue à la Quête de Ramayana",
		"start_game": "Commencer le Jeu",
		"continue": "Continuer",
		"settings": "Paramètres",
		"quit": "Quitter",
		"inventory": "Inventaire",
		"quests": "Quêtes",
		"skills": "Compétences",
		"map": "Carte",
		"health": "Santé",
		"mana": "Mana",
		"level": "Niveau",
		"experience": "Expérience"
	}

func set_language(language_code: String) -> bool:
	if language_code in translations:
		set_state("current_language", language_code)
		language_changed.emit(language_code)
		emit_event("language_changed", language_code)
		return true
	return false

func get_current_language() -> String:
	return get_state("current_language", "en")

func get_text(key: String) -> String:
	var lang = get_current_language()
	var lang_dict = translations.get(lang, {})
	return lang_dict.get(key, key)

func get_available_languages() -> Array:
	return translations.keys()

func add_translation(language_code: String, key: String, text: String) -> void:
	if language_code not in translations:
		translations[language_code] = {}
	translations[language_code][key] = text
	emit_event("translation_added", language_code)

func get_language_text() -> String:
	return "Language: %s" % get_current_language().capitalize()
