class_name AggregateTimer
## Benchmarks repeated events that occur independently and in any order.

static var _count_by_label: Dictionary[String, int] = {}
static var _total_duration_by_label: Dictionary[String, int] = {}
static var _last_time_by_label: Dictionary[String, int] = {}

static func clear() -> void:
	_count_by_label.clear()
	_total_duration_by_label.clear()
	_last_time_by_label.clear()


static func start(label: String) -> void:
	_last_time_by_label[label] = Time.get_ticks_usec()


static func end(label: String) -> void:
	if not _count_by_label.has(label):
		_count_by_label[label] = 0
	_count_by_label[label] += 1
	if not _total_duration_by_label.has(label):
		_total_duration_by_label[label] = 0
	_total_duration_by_label[label] += Time.get_ticks_usec() - _last_time_by_label[label]
	_last_time_by_label.erase(label)


static func print_results() -> void:
	var total_total: int = 0
	for key: String in _count_by_label:
		print("Benchmark %s: count=%s total=%.3f avg=%.3f" % [
				key,
				_count_by_label[key],
				_total_duration_by_label[key] / 1000.0,
				_total_duration_by_label[key] / 1000.0 / _count_by_label[key]])
		total_total += _total_duration_by_label[key]
	
	print("Total: %.3f" % [total_total / 1000.0])
