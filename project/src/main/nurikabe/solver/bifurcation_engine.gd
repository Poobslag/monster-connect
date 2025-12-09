class_name BifurcationEngine

var _scenarios_by_key: Dictionary[String, BifurcationScenario] = {}

func clear() -> void:
	_scenarios_by_key.clear()


func get_scenario_keys() -> Array[String]:
	return _scenarios_by_key.keys()


func add_scenario(board: SolverBoard, key: String, cells: Array[Vector2i],
		assumptions: Dictionary[Vector2i, int],
		deductions: Array[Deduction]) -> void:
	var combo_key: String = _combo_key(key, cells)
	if not _scenarios_by_key.has(combo_key):
		_scenarios_by_key[combo_key] = BifurcationScenario.new(board, assumptions, deductions)


func step(scenario_key: String) -> void:
	if not should_deduce(scenario_key):
		return
	var scenario: BifurcationScenario = _scenarios_by_key[scenario_key]
	scenario.step()


func should_deduce(scenario_key: String) -> bool:
	return _scenarios_by_key[scenario_key].should_deduce()


func has_available_probes() -> bool:
	return _scenarios_by_key.values().any(func(scenario: BifurcationScenario) -> bool:
		return scenario.should_deduce() and scenario.has_available_probes())


func get_scenario_count() -> int:
	return _scenarios_by_key.size()


func has_new_local_contradictions() -> bool:
	return _scenarios_by_key.values().any(func(scenario: BifurcationScenario) -> bool:
		return scenario.should_deduce() and scenario.has_new_local_contradictions())


func has_new_contradictions(mode: SolverBoard.ValidationMode = SolverBoard.VALIDATE_SIMPLE) -> bool:
	return _scenarios_by_key.values().any(func(scenario: BifurcationScenario) -> bool:
		return scenario.should_deduce() and scenario.has_new_contradictions(mode))


func scenario_has_new_local_contradictions(key: String) -> bool:
	var scenario: BifurcationScenario = _scenarios_by_key[key]
	return scenario.should_deduce() and scenario.has_new_local_contradictions()


func scenario_has_new_contradictions(key: String,
		mode: SolverBoard.ValidationMode = SolverBoard.VALIDATE_SIMPLE) -> bool:
	var scenario: BifurcationScenario = _scenarios_by_key[key]
	return scenario.should_deduce() and scenario.has_new_contradictions(mode)


func get_scenario_deductions(key: String) -> Array[Deduction]:
	return _scenarios_by_key[key].deductions


func print_scenarios() -> void:
	var keys: Array[String] = get_scenario_keys()
	print("%s bifurcation scenarios:" % [keys.size()])
	for i in keys.size():
		print(" (%s) %s" % [i, keys[i]])


func _combo_key(key: String, cells: Array[Vector2i] = []) -> String:
	return key if cells.is_empty() else key + " ".join(cells)
