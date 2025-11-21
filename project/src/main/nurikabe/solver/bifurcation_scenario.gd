class_name BifurcationScenario

var solver: Solver = Solver.new()
var board: SolverBoard
var assumptions: Dictionary[Vector2i, int]
var deductions: Array[Deduction]

var _change_cells: Array[Vector2i] = []

var _local_validation_result: String = ""
var _local_validation_result_dirty: bool = false

func _init(init_board: SolverBoard,
		init_assumptions: Dictionary[Vector2i, int],
		init_deductions: Array[Deduction]) -> void:
	board = init_board
	assumptions = init_assumptions
	deductions = init_deductions
	_build()


func _build() -> void:
	solver.board = board.duplicate()
	for assumption_cell in assumptions:
		solver.add_deduction(assumption_cell, assumptions[assumption_cell], Deduction.Reason.ASSUMPTION)
	_change_cells.append_array(solver.deductions.cells.keys())
	solver.apply_changes()


func is_queue_empty() -> bool:
	return solver.is_queue_empty()


func step() -> void:
	if has_new_local_contradictions():
		return
	
	solver.step()
	if solver.deductions.has_changes():
		_change_cells.append_array(solver.deductions.cells.keys())
		solver.apply_changes()
		_local_validation_result_dirty = true


func has_new_local_contradictions() -> bool:
	if _local_validation_result_dirty:
		_local_validation_result = solver.board.validate_local(_change_cells)
		_local_validation_result_dirty = false
	return _local_validation_result != ""


func has_new_contradictions(mode: SolverBoard.ValidationMode = SolverBoard.VALIDATE_SIMPLE) -> bool:
	var initial_validation_result: SolverBoard.ValidationResult = board.validate(mode)
	var last_validation_result: SolverBoard.ValidationResult = solver.board.validate(mode)
	return last_validation_result.error_count > initial_validation_result.error_count
