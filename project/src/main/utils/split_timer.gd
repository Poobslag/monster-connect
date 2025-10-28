class_name SplitTimer

static var _splits: Dictionary[String, int] = {}
static var _last_time: int = 0
static var _prev_label: String

static func start(label: String = "start") -> void:
	_split_internal(label)


static func split(label: String) -> void:
	_split_internal(label)


static func end() -> void:
	_split_internal("")


static func _split_internal(label: String) -> void:
	if _prev_label:
		if not _splits.has(_prev_label):
			_splits[_prev_label] = 0
		_splits[_prev_label] += Time.get_ticks_usec() - _last_time
	_last_time = Time.get_ticks_usec()
	_prev_label = label


static func print_results() -> void:
	for key in _splits:
		print("Benchmark %s: %.3f msec" % [key, _splits[key] / 1000.0])
