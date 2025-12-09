class_name ProbeLibrary

var board: SolverBoard
var _probes: Dictionary[String, Probe] = {}
var _probe_history: Dictionary[String, int] = {}

func clear() -> void:
	_probe_history.clear()
	_probes.clear()


func clear_history() -> void:
	_probe_history.clear()


func get_probe_keys() -> Array[String]:
	return _probes.keys()


func add_probe(callable: Callable) -> ProbeBuilder:
	if has_probe(callable):
		return ProbeBuilder.new(Probe.new(Callable()))
	var probe: Probe = Probe.new(callable)
	_probes[probe.key] = probe
	return ProbeBuilder.new(probe)


func get_available_probes() -> Array[Probe]:
	var available: Array[Probe] = []
	for key: String in _probes:
		var probe: Probe = _probes[key]
		if _probe_history.get(key) == board.version \
				and key != "run_bifurcation_step":
			continue
		# filter out stale probes
		if probe.one_shot and probe.deduction_cells \
				and not probe.deduction_cells.any(func(c: Vector2i) -> bool:
					return board.get_cell(c) == NurikabeUtils.CELL_EMPTY):
			_probes.erase(key)
		available.append(probe)
	return available


func get_last_run(probe: Probe) -> int:
	return _probe_history.get(probe.key, -1)


func get_probe(callable: Callable) -> Probe:
	return _probes.get(Probe.probe_key(callable))


func has_probe(callable: Callable) -> bool:
	return _probes.has(Probe.probe_key(callable))


func has_available_probes() -> bool:
	var result: bool = false
	for key: String in _probes:
		if _probe_history.get(key) == board.version \
				and key != "run_bifurcation_step":
			continue
		result = true
		break
	return result


func print_available_probes() -> void:
	var available_probes: Array[Probe] = get_available_probes()
	print("%s available probes:" % [available_probes.size()])
	for i in available_probes.size():
		var probe: Probe = available_probes[i]
		print(" (%s) %s" % [i, probe.key])


func size() -> int:
	return _probes.size()


func _on_solver_about_to_run_probe(probe: Probe) -> void:
	if probe.one_shot:
		_probes.erase(probe.key)
	else:
		_probe_history[probe.key] = board.version


class ProbeBuilder:
	var probe: Probe
	
	func _init(init_probe: Probe) -> void:
		probe = init_probe
	
	
	func set_one_shot(one_shot: bool = true) -> ProbeBuilder:
		probe.one_shot = one_shot
		return self
	
	
	func set_bifurcation(bifurcation: bool = true) -> ProbeBuilder:
		probe.bifurcation = bifurcation
		return self
	
	
	func set_startup(startup: bool = true) -> ProbeBuilder:
		probe.startup = startup
		return self
	
	
	func deduction_cells(cells: Array[Vector2i]) -> ProbeBuilder:
		probe.add_deduction_cells(cells)
		return self
	
	
	func deduction_cell(cell: Vector2i) -> ProbeBuilder:
		probe.add_deduction_cell(cell)
		return self
