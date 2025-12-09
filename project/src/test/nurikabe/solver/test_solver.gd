class_name TestSolver
extends GutTest
## Framework for testing the Solver.

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

var solver: Solver = Solver.new(false)
var grid: Array[String] = []

func before_each() -> void:
	solver.clear(false)
	solver.decision_manager.strategy = DecisionManager.Strategy.FIRST


func assert_deductions(callable: Callable, expected_str_array: Array[String]) -> void:
	solver.board = SolverTestUtils.init_board(grid)
	callable.call()
	solver.run_all_probes()
	var actual_str_array: Array[String] = deductions_to_strings(solver.deductions.deductions)
	assert_eq(str(actual_str_array), str(expected_str_array))


func deductions_to_strings(deductions: Array[Deduction]) -> Array[String]:
	var result: Array[String] = []
	var sorted_changes: Array[Deduction] = deductions.duplicate()
	sorted_changes.sort_custom(func(a: Deduction, b: Deduction) -> bool: return a.pos < b.pos)
	for change: Deduction in sorted_changes:
		result.append(str(change))
	return result
