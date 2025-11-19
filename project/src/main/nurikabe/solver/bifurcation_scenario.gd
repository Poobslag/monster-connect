class_name BifurcationScenario

var solver: Solver = Solver.new()
var board: SolverBoard
var assumptions: Dictionary[Vector2i, int]
var deductions: Array[Deduction]
var _last_validation_result: SolverBoard.ValidationResult
var _initial_validation_result: SolverBoard.ValidationResult

func _init(init_board: SolverBoard,
		init_assumptions: Dictionary[Vector2i, int],
		init_deductions: Array[Deduction]) -> void:
	board = init_board
	assumptions = init_assumptions
	deductions = init_deductions
	_build()


func _build() -> void:
	_initial_validation_result = board.validate_simple()
	solver.board = board.duplicate()
	for assumption_cell in assumptions:
		solver.add_deduction(assumption_cell, assumptions[assumption_cell], Deduction.Reason.ASSUMPTION)
	solver.apply_changes()
	_last_validation_result = solver.board.validate_simple()


func is_queue_empty() -> bool:
	return solver.is_queue_empty()


func step() -> void:
	if _last_validation_result.error_count > _initial_validation_result.error_count or solver.is_queue_empty():
		return
	
	solver.step()
	solver.apply_changes()


func has_new_contradictions() -> bool:
	_last_validation_result = solver.board.validate_simple()
	return _last_validation_result.error_count > _initial_validation_result.error_count
