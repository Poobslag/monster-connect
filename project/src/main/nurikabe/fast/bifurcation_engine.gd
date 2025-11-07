class_name BifurcationEngine

var _scenarios_by_key: Dictionary[String, BifurcationScenario] = {}

func clear() -> void:
	_scenarios_by_key.clear()


func add_scenario(board: FastBoard,
		assumptions: Dictionary[Vector2i, String],
		deductions: Array[FastDeduction]) -> void:
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
	var result: bool = true
	for scenario_key: String in _scenarios_by_key:
		var scenario: BifurcationScenario = _scenarios_by_key[scenario_key]
		if not scenario.is_queue_empty():
			result = false
	return result


func get_scenario_count() -> int:
	return _scenarios_by_key.size()


func has_contradictions() -> bool:
	var result: bool = false
	for scenario_key: String in _scenarios_by_key:
		var scenario: BifurcationScenario = _scenarios_by_key[scenario_key]
		if scenario.has_new_contradictions():
			result = true
	return result


func get_confirmed_deductions() -> Array[FastDeduction]:
	var result: Array[FastDeduction] = []
	for scenario_key: String in _scenarios_by_key:
		var scenario: BifurcationScenario = _scenarios_by_key[scenario_key]
		if scenario.has_new_contradictions():
			result.append_array(scenario.deductions)
	return result
