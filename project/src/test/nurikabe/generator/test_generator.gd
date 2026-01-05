class_name TestGenerator
extends GutTest
## Framework for testing the Generator.

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

var generator: Generator = Generator.new()
var grid: Array[String] = []

func before_each() -> void:
	generator.rng.seed = 0 # avoid randomness
	generator.clear()


func assert_placements(callable: Callable, expected_str_array: Array[String]) -> void:
	generator.board = GeneratorTestUtils.init_board(grid)
	callable.call()
	var actual_str_array: Array[String] = placements_to_strings(generator.placements.placements)
	assert_eq(str(actual_str_array), str(expected_str_array))


func assert_clue_minimum_changes(expected_str_array: Array[String]) -> void:
	var actual_str_array: Array[String] = clue_minimum_changes_to_strings(generator.placements.clue_minimum_changes)
	assert_eq(str(actual_str_array), str(expected_str_array))


func placements_to_strings(placements: Array[Placement]) -> Array[String]:
	var result: Array[String] = []
	var sorted_changes: Array[Placement] = placements.duplicate()
	sorted_changes.sort_custom(func(a: Placement, b: Placement) -> bool: return a.pos < b.pos)
	for change: Placement in sorted_changes:
		result.append(str(change))
	return result


func clue_minimum_changes_to_strings(clue_minimum_changes: Array[Dictionary]) -> Array[String]:
	var result: Array[String] = []
	var sorted_changes: Array[Dictionary] = clue_minimum_changes.duplicate()
	sorted_changes.sort_custom( \
			func(a: Dictionary[String, Variant], b: Dictionary[String, Variant]) -> bool: return a["pos"] < b["pos"])
	for change: Dictionary[String, Variant] in sorted_changes:
		result.append(str(change))
	return result
