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
