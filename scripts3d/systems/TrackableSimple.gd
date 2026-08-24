extends BaseSystemSimple
class_name TrackableSimple

class Track:
	var id: String
	var title: String
	var progress: int = 0
	var target: int = 1
	var completed: bool = false
	var type: String = "quest"
	var rewards: Dictionary = {}

	func _init(p_id: String, p_title: String, p_type: String = "quest") -> void:
		id = p_id
		title = p_title
		type = p_type

	func advance(amount: int = 1) -> bool:
		progress = mini(progress + amount, target)
		return progress >= target

var active: Array[Track] = []
var completed: Array[Track] = []

signal track_started(track: Track)
signal track_progress(track: Track)
signal track_completed(track: Track)

func start(id: String, title: String, target_count: int = 1, track_type: String = "quest") -> Track:
	var track = Track.new(id, title, track_type)
	track.target = target_count
	active.append(track)
	track_started.emit(track)
	return track

func advance(track_id: String, amount: int = 1) -> bool:
	for track in active:
		if track.id == track_id:
			if track.advance(amount):
				active.erase(track)
				completed.append(track)
				track_completed.emit(track)
				return true
			else:
				track_progress.emit(track)
				return false
	return false

func complete(track_id: String) -> bool:
	return advance(track_id, 999)

func get_active() -> Array[Track]:
	return active

func get_completed() -> Array[Track]:
	return completed

func to_text(prefix: String = "") -> String:
	var text = "%s[%d]:\n" % [prefix, active.size()]
	for t in active:
		text += "%s (%d/%d)\n" % [t.title, t.progress, t.target]
	return text if not active.is_empty() else "%sNone" % prefix
