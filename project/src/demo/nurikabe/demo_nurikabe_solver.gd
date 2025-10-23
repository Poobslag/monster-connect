extends Node
## [b]Keys:[/b][br]
## 	[kbd]Q[/kbd]: Solve.

func _input(event: InputEvent) -> void:
	match Utils.key_press(event):
		KEY_Q:
			solve()


func solve() -> void:
	var changes: Array[Dictionary] = []
	
	if not %MessageLabel.text.is_empty():
		%MessageLabel.text += "--------\n"
	
	var solver: NurikabeSolver = NurikabeSolver.new()
	
	if changes.is_empty():
		changes = run_rules(solver, solver.starting_techniques, changes)
	
	if changes.is_empty():
		changes = run_rules(solver, solver.rules, changes)
	
	if changes.is_empty():
		%MessageLabel.text += "(no changes)\n"
	
	%GameBoard.set_cell_strings(changes)


func run_rules(solver: NurikabeSolver, rules: Array[Callable], changes: Array[Dictionary]) -> Array[Dictionary]:
	var board: NurikabeBoardModel = %GameBoard.to_model()
	for callable: Callable in rules:
		callable.call(board)
	var deduction_positions_by_reason: Dictionary[String, Array] = {}
	for deduction in solver.solver_pass.deductions:
		var reason_name: String = Utils.enum_to_snake_case(NurikabeUtils.Reason, deduction["reason"])
		if not deduction_positions_by_reason.has(reason_name):
			deduction_positions_by_reason[reason_name] = []
		deduction_positions_by_reason[reason_name].append(deduction["pos"])
	for reason_name: String in deduction_positions_by_reason:
		%MessageLabel.text += "%s: %s\n" % [reason_name, deduction_positions_by_reason[reason_name]]
	changes.append_array(solver.solver_pass.get_changes())
	return changes
