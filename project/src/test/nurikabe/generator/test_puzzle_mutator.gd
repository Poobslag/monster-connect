extends GutTest

var mutator: PuzzleMutator

func test_fun_weights_exact() -> void:
	var board: SolverBoard = SolverBoard.new()
	mutator = PuzzleMutator.new(board)
	mutator.difficulty = 0.0
	assert_fun_weight(Deduction.FunAxis.FUN_BIFURCATE, -1.0)
	
	mutator.difficulty = 1.0
	assert_fun_weight(Deduction.FunAxis.FUN_BIFURCATE, 2.0)


func assert_fun_weight(fun_axis: Deduction.FunAxis, expected: float) -> void:
	assert_almost_eq(mutator.fun_weights[fun_axis], expected, 0.001)


func test_fun_weights_interpolated() -> void:
	var board: SolverBoard = SolverBoard.new()
	mutator = PuzzleMutator.new(board)
	mutator.difficulty = 0.25
	assert_fun_weight(Deduction.FunAxis.FUN_THINK, -0.5)
	
	mutator.difficulty = 0.30
	assert_fun_weight(Deduction.FunAxis.FUN_THINK, -0.2)
	
	mutator.difficulty = 0.35
	assert_fun_weight(Deduction.FunAxis.FUN_THINK, 0.1)
	
	mutator.difficulty = 0.40
	assert_fun_weight(Deduction.FunAxis.FUN_THINK, 0.4)
	
	mutator.difficulty = 0.45
	assert_fun_weight(Deduction.FunAxis.FUN_THINK, 0.7)
	
	mutator.difficulty = 0.50
	assert_fun_weight(Deduction.FunAxis.FUN_THINK, 1.0)


func test_fun_weights_interpolated_min() -> void:
	var board: SolverBoard = SolverBoard.new()
	mutator = PuzzleMutator.new(board)
	mutator.difficulty = 0.25
	assert_fun_weight(Deduction.FunAxis.FUN_FAST, 2.0)
	
	mutator.difficulty = 0.125
	assert_fun_weight(Deduction.FunAxis.FUN_FAST, 3.0)
	
	mutator.difficulty = 0.0
	assert_fun_weight(Deduction.FunAxis.FUN_FAST, 4.0)
	
	mutator.difficulty = -1.0
	assert_fun_weight(Deduction.FunAxis.FUN_FAST, 12.0)


func test_fun_weights_interpolated_max() -> void:
	var board: SolverBoard = SolverBoard.new()
	mutator = PuzzleMutator.new(board)
	mutator.difficulty = 0.75
	assert_fun_weight(Deduction.FunAxis.FUN_BIFURCATE, 1.0)
	
	mutator.difficulty = 0.875
	assert_fun_weight(Deduction.FunAxis.FUN_BIFURCATE, 1.5)
	
	mutator.difficulty = 1.00
	assert_fun_weight(Deduction.FunAxis.FUN_BIFURCATE, 2.0)
	
	mutator.difficulty = 2.00
	assert_fun_weight(Deduction.FunAxis.FUN_BIFURCATE, 6.0)
