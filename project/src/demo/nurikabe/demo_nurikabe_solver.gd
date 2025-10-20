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
	for callable: Callable in [
		solver.deduce_joined_island,
		solver.deduce_unclued_island,
		solver.deduce_island_too_large,
		solver.deduce_island_too_small,
		solver.deduce_pools,
		solver.deduce_split_walls,
	]:
		var deduction: NurikabeSolver.Deduction = callable.call(board)
		if not deduction.changes.is_empty():
			var deduction_name: String = callable.get_method()
			var deduction_positions: Array[Vector2i] = []
			for change: Dictionary[String, Variant] in deduction.changes:
				deduction_positions.append(change["pos"])
			%MessageLabel.text += "%s: %s\n" % [deduction_name, deduction_positions]
			changes.append_array(deduction.changes)
	
	if changes.is_empty():
		%MessageLabel.text += "(no changes)\n"
	
	%GameBoard.set_cell_strings(changes)
