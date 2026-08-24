extends BaseSystemSimple

class_name ArchiveSimple

class Book:
	var id: String
	var title: String
	var author: String
	var content: String
	var discovered: bool
	var pages: int
	func _init(p_id: String, p_title: String, p_author: String, p_content: String, p_pages: int) -> void:
		id = p_id
		title = p_title
		author = p_author
		content = p_content
		discovered = false
		pages = p_pages

var books: Array[Book] = []

signal book_discovered(book: Book)
signal book_read(book_id: String)

func _ready() -> void:
	set_state("discovered_books", [])
	set_state("read_books", [])
	set_state("book_read_progress", {})
	set_state("author_reputation", {})
	set_state("book_categories", {})
	set_state("reading_history", [])
	set_state("knowledge_progression", {})
	set_state("lore_levels", {})
	set_state("book_recommendations", [])
	_initialize_books()

func _initialize_books() -> void:
	books = [
		Book.new("b1", "The Quest for Sita", "Ancient Scribe", "A tale of Rama's great journey...", 100),
		Book.new("b2", "Hanuman's Tales", "Monkey Historian", "Stories of the mighty companion...", 85),
		Book.new("b3", "Forest Secrets", "Sage Wisdom", "Knowledge of the enchanted forest...", 120),
		Book.new("b4", "Demon Lore", "Dark Scholar", "Understanding the realm of demons...", 150),
		Book.new("b5", "Sacred Rituals", "Temple Keeper", "Ancient ceremonies and blessings...", 75)
	]

func discover_book(book_id: String) -> bool:
	var book = _get_book(book_id)
	if book and not book.discovered:
		book.discovered = true
		var discovered = get_state("discovered_books", [])
		discovered.append(book_id)
		set_state("discovered_books", discovered)
		book_discovered.emit(book)
		emit_event("book_discovered", book_id)
		return true
	return false

func read_book(book_id: String) -> String:
	var book = _get_book(book_id)
	if book and book.discovered:
		var read = get_state("read_books", [])
		if book_id not in read:
			read.append(book_id)
			set_state("read_books", read)
		book_read.emit(book_id)
		emit_event("book_read", book_id)
		return book.content
	return ""

func get_book(book_id: String) -> Book:
	return _get_book(book_id)

func get_discovered_books() -> Array[Book]:
	var discovered_ids = get_state("discovered_books", [])
	var discovered: Array[Book] = []
	for b in books:
		if b.id in discovered_ids:
			discovered.append(b)
	return discovered

func get_read_books() -> Array[Book]:
	var read_ids = get_state("read_books", [])
	var read: Array[Book] = []
	for b in books:
		if b.id in read_ids:
			read.append(b)
	return read

func get_lore_percentage() -> float:
	var read_ids = get_state("read_books", [])
	if books.is_empty():
		return 0.0
	return (float(read_ids.size()) / float(books.size())) * 100.0

func get_archive_text() -> String:
	var discovered = get_discovered_books()
	var read = get_read_books()
	var text = "Archive\nDiscovered: %d/%d | Read: %d | Lore: %.0f%%\n" % [discovered.size(), books.size(), read.size(), get_lore_percentage()]
	for book in discovered.slice(0, 3):
		var mark = "✓" if book.id in get_state("read_books", []) else "○"
		text += "%s %s (%d pages)\n" % [mark, book.title, book.pages]
	return text

func _get_book(book_id: String) -> Book:
	for book in books:
		if book.id == book_id:
			return book
	return null

func set_book_read_progress(book_id: String, progress: float) -> void:
	var prog = get_state("book_read_progress", {})
	prog[book_id] = clampf(progress, 0.0, 1.0)
	set_state("book_read_progress", prog)

func get_book_read_progress(book_id: String) -> float:
	var prog = get_state("book_read_progress", {})
	return prog.get(book_id, 0.0)

func update_author_reputation(author: String, change: float) -> void:
	var reputation = get_state("author_reputation", {})
	reputation[author] = reputation.get(author, 0.0) + change
	set_state("author_reputation", reputation)
	emit_event("author_reputation_changed", author)

func categorize_book(book_id: String, category: String) -> void:
	var categories = get_state("book_categories", {})
	if book_id not in categories:
		categories[book_id] = []
	categories[book_id].append(category)
	set_state("book_categories", categories)

func record_reading_session(book_id: String, duration_ms: int, pages_read: int) -> void:
	var history = get_state("reading_history", [])
	history.append({"book": book_id, "duration": duration_ms, "pages": pages_read, "time": Time.get_ticks_msec()})
	if history.size() > 100:
		history.pop_front()
	set_state("reading_history", history)

func track_knowledge_gain(knowledge_id: String, value: float) -> void:
	var knowledge = get_state("knowledge_progression", {})
	knowledge[knowledge_id] = knowledge.get(knowledge_id, 0.0) + value
	set_state("knowledge_progression", knowledge)
	emit_event("knowledge_gained", knowledge_id)

func set_lore_level(lore_type: String, level: int) -> void:
	var levels = get_state("lore_levels", {})
	levels[lore_type] = level
	set_state("lore_levels", levels)
	emit_event("lore_level_set", lore_type)

func get_lore_level(lore_type: String) -> int:
	var levels = get_state("lore_levels", {})
	return levels.get(lore_type, 0)

func add_recommendation(book_id: String, reason: String) -> void:
	var recommendations = get_state("book_recommendations", [])
	recommendations.append({"book": book_id, "reason": reason, "time": Time.get_ticks_msec()})
	if recommendations.size() > 30:
		recommendations.pop_front()
	set_state("book_recommendations", recommendations)

func get_recommended_books() -> Array:
	return get_state("book_recommendations", [])

func get_total_pages_read() -> int:
	var history = get_state("reading_history", [])
	var total = 0
	for session in history:
		total += session["pages"]
	return total

func get_author_reputation(author: String) -> float:
	var reputation = get_state("author_reputation", {})
	return reputation.get(author, 0.0)
