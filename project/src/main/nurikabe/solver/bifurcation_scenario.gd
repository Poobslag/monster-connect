class_name BifurcationScenario

var solver: Solver = Solver.new()
var board: SolverBoard
var assumptions: Dictionary[Vector2i, int]
var deductions: Array[Deduction]

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
	solver.apply_changes()


func is_queue_empty() -> bool:
	return solver.is_queue_empty()


func step() -> void:
	var initial_validation_result: SolverBoard.ValidationResult = board.validate(SolverBoard.VALIDATE_SIMPLE)
	var last_validation_result: SolverBoard.ValidationResult  = solver.board.validate(SolverBoard.VALIDATE_SIMPLE)
	if last_validation_result.error_count > initial_validation_result.error_count or solver.is_queue_empty():
		return
	
	solver.step()
	solver.apply_changes()


func has_new_contradictions(mode: SolverBoard.ValidationMode = SolverBoard.VALIDATE_SIMPLE) -> bool:
	var initial_validation_result: SolverBoard.ValidationResult = board.validate(mode)
	var last_validation_result: SolverBoard.ValidationResult  = solver.board.validate(mode)
	return last_validation_result.error_count > initial_validation_result.error_count
