@tool
extends Node
## [b]Keys:[/b][br]
## 	[kbd]Q[/kbd]: Solve one step.
## 	[kbd]W[/kbd]: Performance test a full solution.
## 	[kbd]P[/kbd]: Print partially solved puzzle to console.

@export_file("*.txt") var puzzle_path: String:
	set(value):
		puzzle_path = value
		_refresh_puzzle_path()

var ran_starting_techniques: bool = false

var performance_data: Dictionary[String, Variant] = {}

func _input(event: InputEvent) -> void:
	match Utils.key_press(event):
		KEY_Q:
			solve()
		KEY_W:
			performance_test()
		KEY_P:
			print_grid_string()


func _ready() -> void:
	_refresh_puzzle_path()


func print_grid_string() -> void:
	%GameBoard.to_model().print_cells()


func solve() -> void:
	var changes: Array[Dictionary] = []
	
	if not %MessageLabel.text.is_empty():
		%MessageLabel.text += "--------\n"
	
	var solver: NurikabeSolver = NurikabeSolver.new()
	
	if changes.is_empty() and not ran_starting_techniques:
		changes = run_techniques(solver, solver.starting_techniques, changes)
		ran_starting_techniques = true
	
	if changes.is_empty():
		changes = run_techniques(solver, solver.basic_techniques, changes)
	
	if changes.is_empty():
		changes = run_techniques(solver, solver.advanced_techniques, changes)
	
	if changes.is_empty():
		changes = run_techniques(solver, [solver.deduce_bifurcation], changes)
	
	if changes.is_empty():
		%MessageLabel.text += "(no changes)\n"
	
	%GameBoard.set_cell_strings(changes)


func performance_test() -> void:
	performance_data.clear()
	ran_starting_techniques = false
	
	var start_time: float = Time.get_ticks_usec()
	var solver: NurikabeSolver = NurikabeSolver.new()
	
	while true:
		if not %MessageLabel.text.is_empty():
			%MessageLabel.text += "--------\n"
		
		var changes: Array[Dictionary] = []
		solver.clear()
		if changes.is_empty() and not ran_starting_techniques:
			changes = run_techniques(solver, solver.starting_techniques, changes)
			ran_starting_techniques = true
		
		if changes.is_empty():
			changes = run_techniques(solver, solver.basic_techniques, changes)
		
		if changes.is_empty():
			changes = run_techniques(solver, solver.advanced_techniques, changes)
		
		if changes.is_empty():
			changes = run_techniques(solver, [solver.deduce_bifurcation], changes)
		
		if changes.is_empty():
			%MessageLabel.text += "(no changes)\n"
			break
		
		%GameBoard.set_cell_strings(changes)
	
	if not %MessageLabel.text.is_empty():
		%MessageLabel.text += "--------\n"
	%MessageLabel.text += "%.3f msec" % [(Time.get_ticks_usec() - start_time) / 1000.0]
	
	var all_techniques: Array[Callable] = []
	for techniques: Array[Callable] in [
			solver.starting_techniques,
			solver.basic_techniques,
			solver.advanced_techniques,
			[solver.deduce_bifurcation] as Array[Callable]]:
		for technique: Callable in techniques:
			if not technique in all_techniques:
				all_techniques.append(technique)
	all_techniques.sort()
	
	var total_call_count: int = 0
	var total_deduction_count: int = 0
	var total_duration: float = 0.0
	for technique: Callable in all_techniques:
		var callable_name: String = technique.get_method()
		var call_count_property: String = "%s_call_count" % [callable_name]
		var call_count: int = performance_data.get(call_count_property, 0)
		
		var deduction_count_property: String = "%s_deduction_count" % [callable_name]
		var deduction_count: int = performance_data.get(deduction_count_property, 0)
		
		var duration_property: String = "%s_duration" % [callable_name]
		var duration: float = performance_data.get(duration_property, 0.0)
		
		print("%s %sx: %.3f msec, %s deductions (avg: %.3f msec, %.3f deductions)" % [
			callable_name,
			call_count,
			duration,
			deduction_count,
			duration / call_count,
			float(deduction_count) / call_count,
		])
		
		total_call_count += call_count
		total_deduction_count += deduction_count
		total_duration += duration
	
	print("%s %sx: %.3f msec, %s deductions (avg: %.3f msec, %.3f deductions)" % [
		"total",
		total_call_count,
		total_duration,
		total_deduction_count,
		total_duration / total_call_count,
		float(total_deduction_count) / total_call_count,
	])


func run_techniques(
			solver: NurikabeSolver,
			techniques: Array[Callable],
			changes: Array[Dictionary]) -> Array[Dictionary]:
	Global.benchmark_start("run_techniques")
	var board: NurikabeBoardModel = %GameBoard.to_model()
	for callable: Callable in techniques:
		var start_ticks_usec: int = Time.get_ticks_usec()
		var old_deduction_cell_count: int = solver.solver_pass.deduction_cells.size()
		callable.call(board)
		var deduction_count: int = solver.solver_pass.deduction_cells.size() - old_deduction_cell_count
		_record_deduction_result(callable, start_ticks_usec, deduction_count)
	var deduction_positions_by_reason: Dictionary[String, Array] = {}
	for deduction: NurikabeDeduction in solver.solver_pass.deductions:
		var reason_name: String = Utils.enum_to_snake_case(NurikabeUtils.Reason, deduction["reason"])
		if not deduction_positions_by_reason.has(reason_name):
			deduction_positions_by_reason[reason_name] = []
		deduction_positions_by_reason[reason_name].append(deduction["pos"])
	for reason_name: String in deduction_positions_by_reason:
		%MessageLabel.text += "%s: %s\n" % [reason_name, deduction_positions_by_reason[reason_name]]
	changes.append_array(solver.solver_pass.get_changes())
	Global.benchmark_end("run_techniques")
	print("(%s)" % [%MessageLabel.text.length()])
	return changes


func _record_deduction_result(callable: Callable, start_ticks_usec: int, deduction_count: int) -> void:
	var call_count_property: String = "%s_call_count" % [callable.get_method()]
	var old_call_count: int = performance_data.get(call_count_property, 0)
	performance_data[call_count_property] = old_call_count + 1
	
	var deduction_count_property: String = "%s_deduction_count" % [callable.get_method()]
	var old_deduction_count: int = performance_data.get(deduction_count_property, 0)
	performance_data[deduction_count_property] = old_deduction_count + deduction_count
	
	var duration_property: String = "%s_duration" % [callable.get_method()]
	var old_duration: float = performance_data.get(duration_property, 0.0)
	var duration: float = (Time.get_ticks_usec() - start_ticks_usec) / 1000.0
	performance_data[duration_property] = old_duration + duration


func _refresh_puzzle_path() -> void:
	if not is_inside_tree():
		return
	
	var s: String = FileAccess.get_file_as_string(puzzle_path)
	var file_lines: PackedStringArray = s.split("\n")
	var puzzle_lines: Array[String] = []
	for file_line: String in file_lines:
		if file_line.begins_with("//"):
			continue
		puzzle_lines.append(file_line)
	%GameBoard.grid_string = "\n".join(PackedStringArray(puzzle_lines))
	%GameBoard.import_grid()
