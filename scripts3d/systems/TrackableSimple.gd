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
	var difficulty: int = 1
	var time_limit: int = 0
	var start_time: int = 0
	var optional_objectives: Array[String] = []
	var optional_progress: Dictionary = {}
	var perfect_completion: bool = true
	var failure_penalty: float = 0.0
	var milestone_rewards: Dictionary = {}
	var failed: bool = false
	var attempts: int = 0

	func _init(p_id: String, p_title: String, p_type: String = "quest") -> void:
		id = p_id
		title = p_title
		type = p_type
		start_time = Time.get_ticks_msec()

	func advance(amount: int = 1) -> bool:
		if progress < target:
			progress = mini(progress + amount, target)
		return progress >= target

	func is_time_expired() -> bool:
		if time_limit == 0:
			return false
		return (Time.get_ticks_msec() - start_time) > (time_limit * 1000)

var active: Array[Track] = []
var completed: Array[Track] = []

signal track_started(track: Track)
signal track_progress(track: Track)
signal track_completed(track: Track)
signal track_failed(track: Track)
signal milestone_reached(data: Dictionary)

func start(id: String, title: String, target_count: int = 1, track_type: String = "quest", difficulty: int = 1) -> Track:
	var track = Track.new(id, title, track_type)
	track.target = target_count
	track.difficulty = difficulty
	track.failure_penalty = difficulty * 0.1
	active.append(track)
	track_started.emit(track)
	return track

func set_track_time_limit(track_id: String, limit_seconds: int) -> void:
	for track in active:
		if track.id == track_id:
			track.time_limit = limit_seconds

func set_track_milestone(track_id: String, milestone: int, reward: Dictionary) -> void:
	for track in active:
		if track.id == track_id:
			track.milestone_rewards[milestone] = reward

func advance(track_id: String, amount: int = 1) -> bool:
	for track in active:
		if track.id == track_id:
			if track.is_time_expired():
				track.failed = true
				active.erase(track)
				track_failed.emit(track)
				return false
			track.advance(amount)
			_check_milestone_reward(track)
			if track.progress >= track.target:
				active.erase(track)
				completed.append(track)
				track_completed.emit(track)
				return true
			else:
				track_progress.emit(track)
				return false
	return false

func _check_milestone_reward(track: Track) -> void:
	for milestone in track.milestone_rewards:
		if track.progress == milestone:
			milestone_reached.emit({"track": track.id, "milestone": milestone})

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
