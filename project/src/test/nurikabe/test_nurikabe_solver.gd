class_name TestNurikabeSolver
extends GutTest
## Framework for testing the Nurikabe Solver.

const CELL_EMPTY: String = NurikabeUtils.CELL_EMPTY
const CELL_INVALID: String = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: String = NurikabeUtils.CELL_ISLAND
const CELL_WALL: String = NurikabeUtils.CELL_WALL

const UNKNOWN_REASON: NurikabeUtils.Reason = NurikabeUtils.UNKNOWN_REASON

## Starting techniques
const ISLAND_OF_ONE: NurikabeUtils.Reason = NurikabeUtils.ISLAND_OF_ONE
const ADJACENT_CLUES: NurikabeUtils.Reason = NurikabeUtils.ADJACENT_CLUES
const DIAGONAL_CLUES: NurikabeUtils.Reason = NurikabeUtils.DIAGONAL_CLUES

## Rules
const JOINED_ISLAND: NurikabeUtils.Reason = NurikabeUtils.JOINED_ISLAND
const UNCLUED_ISLAND: NurikabeUtils.Reason = NurikabeUtils.UNCLUED_ISLAND
const ISLAND_TOO_LARGE: NurikabeUtils.Reason = NurikabeUtils.ISLAND_TOO_LARGE
const ISLAND_TOO_SMALL: NurikabeUtils.Reason = NurikabeUtils.ISLAND_TOO_SMALL
const POOLS: NurikabeUtils.Reason = NurikabeUtils.POOLS
const SPLIT_WALLS: NurikabeUtils.Reason = NurikabeUtils.SPLIT_WALLS

## Basic techniques
const CORNER_ISLAND: NurikabeUtils.Reason = NurikabeUtils.CORNER_ISLAND
const ISLAND_BUBBLE: NurikabeUtils.Reason = NurikabeUtils.ISLAND_BUBBLE
const ISLAND_BUFFER: NurikabeUtils.Reason = NurikabeUtils.ISLAND_BUFFER
const ISLAND_CHOKEPOINT: NurikabeUtils.Reason = NurikabeUtils.ISLAND_CHOKEPOINT
const ISLAND_CONNECTOR: NurikabeUtils.Reason = NurikabeUtils.ISLAND_CONNECTOR
const ISLAND_DIVIDER: NurikabeUtils.Reason = NurikabeUtils.ISLAND_DIVIDER
const ISLAND_EXPANSION: NurikabeUtils.Reason = NurikabeUtils.ISLAND_EXPANSION
const ISLAND_MOAT: NurikabeUtils.Reason = NurikabeUtils.ISLAND_MOAT
const POOL_TRIPLET: NurikabeUtils.Reason = NurikabeUtils.POOL_TRIPLET
const UNREACHABLE_SQUARE: NurikabeUtils.Reason = NurikabeUtils.UNREACHABLE_SQUARE
const WALL_BUBBLE: NurikabeUtils.Reason = NurikabeUtils.WALL_BUBBLE
const WALL_CONNECTOR: NurikabeUtils.Reason = NurikabeUtils.WALL_CONNECTOR
const WALL_EXPANSION: NurikabeUtils.Reason = NurikabeUtils.WALL_EXPANSION

var solver: NurikabeSolver = NurikabeSolver.new()
var grid: Array[String] = []

func before_each() -> void:
	solver.clear()


func assert_deduction(callable: Callable, expected: Array[NurikabeDeduction]) -> void:
	callable.call(init_model())
	var actual_str_array: Array[String] = deductions_to_strings(solver.solver_pass.deductions)
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
