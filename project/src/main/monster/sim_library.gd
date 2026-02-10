extends Node

const PROFILE_DIR: String = "res://assets/main/monster/sim/"

var _available_profiles: Array[String] = []

var _profile_cache: Dictionary[String, SimProfile] = {}
var _profile_queue: Array[String] = []
var _next_profile_index: int = 0

func _ready() -> void:
	_scan_available_profiles()


func _scan_available_profiles() -> void:
	var dir: DirAccess = DirAccess.open(PROFILE_DIR)
	dir.list_dir_begin()
	var filename: String = dir.get_next()
	while filename != "":
		if filename.ends_with(".txt"):
			_available_profiles.append(PROFILE_DIR.path_join(filename))
		filename = dir.get_next()
	
	_profile_queue = _available_profiles.duplicate()
	_profile_queue.shuffle()
	_next_profile_index = 0


func get_next_profile() -> SimProfile:
	if _profile_queue.is_empty():
		push_warning("profile_queue is empty")
		return null
	
	var path: String = _profile_queue[_next_profile_index]
	var result: SimProfile
	if not _profile_cache.has(path):
		var saver: MonsterSaver = MonsterSaver.new()
		var profile: SimProfile = saver.load_sim_profile(path)
		_profile_cache[path] = profile
	result = _profile_cache[path]
	_next_profile_index = (_next_profile_index + 1) % _available_profiles.size()
	return result
