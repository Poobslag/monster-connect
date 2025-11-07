class_name BifurcationScenario

var solver: FastSolver = FastSolver.new()
var board: FastBoard
var assumptions: Dictionary[Vector2i, String]
var deductions: Array[FastDeduction]
var _last_validation_result: FastBoard.ValidationResult
var _initial_validation_result: FastBoard.ValidationResult

func _init(init_board: FastBoard,
		init_assumptions: Dictionary[Vector2i, String],
		init_deductions: Array[FastDeduction]) -> void:
	board = init_board
	assumptions = init_assumptions
	deductions = init_deductions
	_build()


func _build() -> void:
	_initial_validation_result = board.validate()
	solver.board = board.duplicate()
	for assumption_cell in assumptions:
		solver.add_deduction(assumption_cell, assumptions[assumption_cell], "bifurcation")
	solver.apply_changes()
	_last_validation_result = solver.board.validate()


func is_queue_empty() -> bool:
	return solver.is_queue_empty()


func step() -> void:
	if _last_validation_result.error_count > _initial_validation_result.error_count or solver.is_queue_empty():
		return
	
	solver.step()
	solver.apply_changes()


func has_new_contradictions() -> bool:
	_last_validation_result = solver.board.validate()
	return _last_validation_result.error_count > _initial_validation_result.error_count
