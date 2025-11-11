class_name BifurcationEngine

var _scenarios_by_key: Dictionary[String, BifurcationScenario] = {}

func clear() -> void:
	_scenarios_by_key.clear()


func add_scenario(board: SolverBoard,
		assumptions: Dictionary[Vector2i, String],
		deductions: Array[Deduction]) -> void:
	var key: String = "%s -> %s" % [assumptions, deductions]
	if not _scenarios_by_key.has(key):
		_scenarios_by_key[key] = BifurcationScenario.new(board, assumptions, deductions)


func step() -> void:
	for scenario_key: String in _scenarios_by_key.keys():
		var scenario: BifurcationScenario = _scenarios_by_key[scenario_key]
		scenario.step()
		if scenario.is_queue_empty():
			_scenarios_by_key.erase(scenario_key)


func is_queue_empty() -> bool:
	return _scenarios_by_key.values().all(func(scenario: BifurcationScenario) -> bool:
		return scenario.is_queue_empty())


func get_scenario_count() -> int:
	return _scenarios_by_key.size()


func has_contradictions() -> bool:
	return _scenarios_by_key.values().any(func(scenario: BifurcationScenario) -> bool:
		return scenario.has_new_contradictions())


func get_confirmed_deductions() -> Array[Deduction]:
	var result: Array[Deduction] = []
	for scenario_key: String in _scenarios_by_key:
		var scenario: BifurcationScenario = _scenarios_by_key[scenario_key]
		if scenario.has_new_contradictions():
			result.append_array(scenario.deductions)
	return result
