extends BaseSystemSimple

class_name LanguageSimple

var translations: Dictionary = {}

signal language_changed(language_code: String)

func _ready() -> void:
	set_state("current_language", "en")
	set_state("language_change_history", [])
	set_state("translation_completeness", {})
	set_state("language_preference_history", [])
	set_state("missing_keys", {})
	set_state("translation_quality_scores", {})
	set_state("language_statistics", {})
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
		var old_language = get_state("current_language", "en")
		set_state("current_language", language_code)
		_record_language_change(old_language, language_code)
		_record_language_preference(language_code)
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
	_update_translation_completeness(language_code)
	emit_event("translation_added", language_code)

func get_language_text() -> String:
	return "Language: %s" % get_current_language().capitalize()

func _record_language_change(old_lang: String, new_lang: String) -> void:
	var history = get_state("language_change_history", [])
	history.append({"from": old_lang, "to": new_lang, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("language_change_history", history)

func _record_language_preference(language_code: String) -> void:
	var prefs = get_state("language_preference_history", [])
	prefs.append({"language": language_code, "time": Time.get_ticks_msec()})
	if prefs.size() > 50:
		prefs.pop_front()
	set_state("language_preference_history", prefs)

func _update_translation_completeness(language_code: String) -> void:
	var completeness = get_state("translation_completeness", {})
	var lang_dict = translations.get(language_code, {})
	completeness[language_code] = lang_dict.size()
	set_state("translation_completeness", completeness)

func record_missing_translation_key(language_code: String, key: String) -> void:
	var missing = get_state("missing_keys", {})
	if language_code not in missing:
		missing[language_code] = []
	if key not in missing[language_code]:
		missing[language_code].append(key)
	set_state("missing_keys", missing)
	emit_event("missing_key_recorded", {"language": language_code, "key": key})

func get_missing_translations(language_code: String) -> Array:
	var missing = get_state("missing_keys", {})
	return missing.get(language_code, [])

func set_translation_quality_score(language_code: String, score: float) -> void:
	var scores = get_state("translation_quality_scores", {})
	scores[language_code] = clampf(score, 0.0, 1.0)
	set_state("translation_quality_scores", scores)

func get_translation_quality_score(language_code: String) -> float:
	var scores = get_state("translation_quality_scores", {})
	return scores.get(language_code, 0.0)

func get_translation_completeness(language_code: String) -> int:
	var completeness = get_state("translation_completeness", {})
	return completeness.get(language_code, 0)

func update_language_statistics() -> void:
	var stats = get_state("language_statistics", {})
	stats["current"] = get_current_language()
	stats["available"] = get_available_languages().size()
	stats["changes"] = get_state("language_change_history", []).size()
	var missing_total = 0
	for lang_keys in get_state("missing_keys", {}).values():
		missing_total += lang_keys.size()
	stats["missing_keys"] = missing_total
	set_state("language_statistics", stats)

func get_language_statistics() -> Dictionary:
	update_language_statistics()
	return get_state("language_statistics", {})
