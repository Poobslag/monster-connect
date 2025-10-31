class_name TestNurikabeSolver
extends GutTest
## Framework for testing the Nurikabe Solver.

const CELL_EMPTY: String = NurikabeUtils.CELL_EMPTY
const CELL_INVALID: String = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: String = NurikabeUtils.CELL_ISLAND
const CELL_WALL: String = NurikabeUtils.CELL_WALL

const UNKNOWN_REASON: NurikabeSolver.Reason = NurikabeSolver.UNKNOWN_REASON

## Starting techniques
const ISLAND_OF_ONE: NurikabeSolver.Reason = NurikabeSolver.ISLAND_OF_ONE
const ADJACENT_CLUES: NurikabeSolver.Reason = NurikabeSolver.ADJACENT_CLUES
const DIAGONAL_CLUES: NurikabeSolver.Reason = NurikabeSolver.DIAGONAL_CLUES

## Rules
const JOINED_ISLAND: NurikabeSolver.Reason = NurikabeSolver.JOINED_ISLAND
const UNCLUED_ISLAND: NurikabeSolver.Reason = NurikabeSolver.UNCLUED_ISLAND
const ISLAND_TOO_LARGE: NurikabeSolver.Reason = NurikabeSolver.ISLAND_TOO_LARGE
const ISLAND_TOO_SMALL: NurikabeSolver.Reason = NurikabeSolver.ISLAND_TOO_SMALL
const POOLS: NurikabeSolver.Reason = NurikabeSolver.POOLS
const SPLIT_WALLS: NurikabeSolver.Reason = NurikabeSolver.SPLIT_WALLS

## Basic techniques
const CORNER_ISLAND: NurikabeSolver.Reason = NurikabeSolver.CORNER_ISLAND
const ISLAND_BUBBLE: NurikabeSolver.Reason = NurikabeSolver.ISLAND_BUBBLE
const ISLAND_BUFFER: NurikabeSolver.Reason = NurikabeSolver.ISLAND_BUFFER
const ISLAND_CHOKEPOINT: NurikabeSolver.Reason = NurikabeSolver.ISLAND_CHOKEPOINT
const ISLAND_CONNECTOR: NurikabeSolver.Reason = NurikabeSolver.ISLAND_CONNECTOR
const ISLAND_DIVIDER: NurikabeSolver.Reason = NurikabeSolver.ISLAND_DIVIDER
const ISLAND_EXPANSION: NurikabeSolver.Reason = NurikabeSolver.ISLAND_EXPANSION
const ISLAND_MOAT: NurikabeSolver.Reason = NurikabeSolver.ISLAND_MOAT
const POOL_TRIPLET: NurikabeSolver.Reason = NurikabeSolver.POOL_TRIPLET
const UNREACHABLE_SQUARE: NurikabeSolver.Reason = NurikabeSolver.UNREACHABLE_SQUARE
const WALL_BUBBLE: NurikabeSolver.Reason = NurikabeSolver.WALL_BUBBLE
const WALL_CONNECTOR: NurikabeSolver.Reason = NurikabeSolver.WALL_CONNECTOR
const WALL_EXPANSION: NurikabeSolver.Reason = NurikabeSolver.WALL_EXPANSION

## Advanced techniques
const FORBIDDEN_COURTYARD: NurikabeSolver.Reason = NurikabeSolver.FORBIDDEN_COURTYARD
const LAST_LIGHT: NurikabeSolver.Reason = NurikabeSolver.LAST_LIGHT
const DEAD_END_WALL: NurikabeSolver.Reason = NurikabeSolver.DEAD_END_WALL
const WALL_STRANGLE: NurikabeSolver.Reason = NurikabeSolver.WALL_STRANGLE

const BIFURCATION: NurikabeSolver.Reason = NurikabeSolver.BIFURCATION

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
