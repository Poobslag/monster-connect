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
	var scenario: BifurcationScenario = _scenarios_by_key[scenario_key]
	scenario.step()


func is_queue_empty() -> bool:
	return _scenarios_by_key.values().all(func(scenario: BifurcationScenario) -> bool:
		return scenario.is_queue_empty())


func get_scenario_count() -> int:
	return _scenarios_by_key.size()


func has_new_contradictions(mode: SolverBoard.ValidationMode = SolverBoard.VALIDATE_SIMPLE) -> bool:
	return _scenarios_by_key.values().any(func(scenario: BifurcationScenario) -> bool:
		return scenario.has_new_contradictions(mode))


func scenario_has_new_contradictions(key: String,
		mode: SolverBoard.ValidationMode = SolverBoard.VALIDATE_SIMPLE) -> bool:
	return _scenarios_by_key[key].has_new_contradictions(mode)


func get_scenario_deductions(key: String) -> Array[Deduction]:
	return _scenarios_by_key[key].deductions


func _combo_key(key: String, cells: Array[Vector2i] = []) -> String:
	return key if cells.is_empty() else key + " ".join(cells)
