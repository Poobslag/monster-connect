extends Node
## [b]Keys:[/b][br]
## 	[kbd]Q[/kbd]: Solve.

func _input(event: InputEvent) -> void:
	match Utils.key_press(event):
		KEY_Q:
			_solve()


func _solve() -> void:
	var board: NurikabeBoardModel = %GameBoard.to_model()
	var solver: NurikabeSolver = NurikabeSolver.new()
	var changes: Array[Dictionary] = []
	
	if not %MessageLabel.text.is_empty():
		%MessageLabel.text += "--------\n"
	for callable: Callable in solver.rules:
		var deductions: Array[NurikabeDeduction] = callable.call(board)
		if deductions.is_empty():
			continue
		var deduction_positions_by_reason: Dictionary[String, Array] = {}
		for deduction: NurikabeDeduction in deductions:
			var reason_name: String = Utils.enum_to_snake_case(NurikabeUtils.Reason, deduction["reason"])
			if not deduction_positions_by_reason.has(reason_name):
				deduction_positions_by_reason[reason_name] = []
			deduction_positions_by_reason[reason_name].append(deduction["pos"])
		for reason_name: String in deduction_positions_by_reason:
			%MessageLabel.text += "%s: %s\n" % [reason_name, deduction_positions_by_reason[reason_name]]
		for deduction: NurikabeDeduction in deductions:
			changes.append(deduction.to_change())
	
	if changes.is_empty():
		%MessageLabel.text += "(no changes)\n"
	
	%GameBoard.set_cell_strings(changes)
