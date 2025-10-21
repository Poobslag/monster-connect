class_name TestNurikabeSolver
extends GutTest
## Framework for testing the Nurikabe Solver.

const CELL_EMPTY: String = NurikabeUtils.CELL_EMPTY
const CELL_INVALID: String = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: String = NurikabeUtils.CELL_ISLAND
const CELL_WALL: String = NurikabeUtils.CELL_WALL

const UNKNOWN_REASON: NurikabeUtils.Reason = NurikabeUtils.UNKNOWN_REASON

## Rules
const JOINED_ISLAND: NurikabeUtils.Reason = NurikabeUtils.JOINED_ISLAND
const UNCLUED_ISLAND: NurikabeUtils.Reason = NurikabeUtils.UNCLUED_ISLAND
const ISLAND_TOO_LARGE: NurikabeUtils.Reason = NurikabeUtils.ISLAND_TOO_LARGE
const ISLAND_TOO_SMALL: NurikabeUtils.Reason = NurikabeUtils.ISLAND_TOO_SMALL
const POOLS: NurikabeUtils.Reason = NurikabeUtils.POOLS
const SPLIT_WALLS: NurikabeUtils.Reason = NurikabeUtils.SPLIT_WALLS

var solver: NurikabeSolver = NurikabeSolver.new()
var grid: Array[String] = []

func assert_deduction(actual: Array[NurikabeDeduction], expected: Array[NurikabeDeduction]) -> void:
	var actual_str_array: Array[String] = deductions_to_strings(actual)
	var expected_str_array: Array[String] = deductions_to_strings(expected)
	assert_eq(actual_str_array, expected_str_array)


func init_model() -> NurikabeBoardModel:
	return NurikabeTestUtils.init_model(grid)


func deductions_to_strings(changes: Array[NurikabeDeduction]) -> Array[String]:
	var result: Array[String] = []
	var sorted_changes: Array[NurikabeDeduction] = changes.duplicate()
	sorted_changes.sort_custom(func(a: NurikabeDeduction, b: NurikabeDeduction) -> bool: return a.pos < b.pos)
	for change: NurikabeDeduction in sorted_changes:
		result.append(str(change))
	return result
