class_name TestFastSolver
extends GutTest
## Framework for testing the Fast Solver.

const CELL_EMPTY: String = NurikabeUtils.CELL_EMPTY
const CELL_INVALID: String = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: String = NurikabeUtils.CELL_ISLAND
const CELL_WALL: String = NurikabeUtils.CELL_WALL

var solver: FastSolver = FastSolver.new()
var grid: Array[String] = []

func before_each() -> void:
	solver.clear()


func assert_deduction(callable: Callable, expected: Array[FastDeduction]) -> void:
	solver.board = FastTestUtils.init_board(grid)
	callable.call()
	solver.run_all_tasks()
	var actual_str_array: Array[String] = deductions_to_strings(solver.deductions.deductions)
	var expected_str_array: Array[String] = deductions_to_strings(expected)
	assert_eq(actual_str_array, expected_str_array)


func deductions_to_strings(deductions: Array[FastDeduction]) -> Array[String]:
	var result: Array[String] = []
	var sorted_changes: Array[FastDeduction] = deductions.duplicate()
	sorted_changes.sort_custom(func(a: FastDeduction, b: FastDeduction) -> bool: return a.pos < b.pos)
	for change: FastDeduction in sorted_changes:
		result.append(str(change))
	return result
