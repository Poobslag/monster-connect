class_name DeductionLogger

const LOG_PATH: String = "user://solver.log"

var solver: Solver
var deduction_info_by_key: Dictionary[String, Dictionary] = {}

var _log: FileAccess:
	get():
		if _log == null:
			_log = FileAccess.open(LOG_PATH, FileAccess.WRITE)
		return _log

func _init(init_solver: Solver) -> void:
	solver = init_solver


func start(key: String, cells: Array[Vector2i] = []) -> void:
	if not solver.log_enabled:
		return
	
	var combo_key: String = _combo_key(key, cells)
	_start_deduction_timer(combo_key)


func pause(key: String, cells: Array[Vector2i] = []) -> void:
	if not solver.log_enabled:
		return
	
	var combo_key: String = _combo_key(key, cells)
	_stop_deduction_timer(combo_key)


func end(key: String, cells: Array[Vector2i] = []) -> void:
	if not solver.log_enabled:
		return
	
	var combo_key: String = _combo_key(key, cells)
	_stop_deduction_timer(combo_key)
	var deduction_info: Dictionary[String, Variant] = deduction_info_by_key.get(combo_key)
	_log.store_string("| %s | %s | %s |\n"
			% [combo_key, deduction_info["deductions_delta"], deduction_info["time_delta"]])
	for probe_key: String in deduction_info["probes_delta"]:
		_log.store_string("+ %s\n" % [probe_key])
	_log.flush()
	_delete_deduction_timer(combo_key)


func _combo_key(key: String, cells: Array[Vector2i] = []) -> String:
	return key if cells.is_empty() else key + " ".join(cells)


func _create_deduction_timer(combo_key: String) -> void:
	deduction_info_by_key[combo_key] = {
		"active": false,
		"deductions_delta": 0,
		"deductions_start": solver.deductions.size(),
		"probes_delta": [] as Array[String],
		"probes_start": [] as Array[String],
		"time_delta": 0,
		"time_start": Time.get_ticks_usec(),
		} as Dictionary[String, Variant]


func _start_deduction_timer(combo_key: String) -> void:
	if not deduction_info_by_key.has(combo_key):
		_create_deduction_timer(combo_key)
	var deduction_info: Dictionary[String, Variant] = deduction_info_by_key[combo_key]
	deduction_info["active"] = true
	deduction_info["deductions_start"] = solver.deductions.size()
	deduction_info["probes_start"] = solver.probe_library.get_probe_keys()
	deduction_info["time_start"] = Time.get_ticks_usec()


func _stop_deduction_timer(combo_key: String) -> void:
	if not deduction_info_by_key.has(combo_key):
		_create_deduction_timer(combo_key)
	var deduction_info: Dictionary[String, Variant] = deduction_info_by_key[combo_key]
	if deduction_info["active"]:
		deduction_info["active"] = false
		deduction_info["deductions_delta"] += solver.deductions.size() - deduction_info["deductions_start"]
		var new_probe_keys: Array[String] = []
		new_probe_keys.assign(Utils.subtract( \
				solver.probe_library.get_probe_keys(), deduction_info["probes_start"]))
		deduction_info["probes_delta"].append_array(new_probe_keys)
		deduction_info["time_delta"] += Time.get_ticks_usec() - deduction_info["time_start"]


func _delete_deduction_timer(combo_key: String) -> void:
	if not deduction_info_by_key.has(combo_key):
		return
	deduction_info_by_key.erase(combo_key)
