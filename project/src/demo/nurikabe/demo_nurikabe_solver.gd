@tool
extends Node
## [b]Keys:[/b][br]
## 	[kbd]Q[/kbd]: Solve.

@export_file("*.txt") var puzzle_path: String:
	set(value):
		puzzle_path = value
		_refresh_puzzle_path()

var ran_starting_techniques: bool = false

func _input(event: InputEvent) -> void:
	match Utils.key_press(event):
		KEY_Q:
			solve()


func _ready() -> void:
	_refresh_puzzle_path()


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


func run_techniques(
			solver: NurikabeSolver,
			techniques: Array[Callable],
			changes: Array[Dictionary]) -> Array[Dictionary]:
	Global.benchmark_start("run_techniques")
	var board: NurikabeBoardModel = %GameBoard.to_model()
	for callable: Callable in techniques:
		callable.call(board)
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
