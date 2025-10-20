extends GutTest

var solver: NurikabeSolver = NurikabeSolver.new()
var grid: Array[String] = []

func test_deduce_joined_island_2() -> void:
	grid = [
		" 3   3",
		"      ",
		"      ",
	]
	var expected: NurikabeSolver.Deduction = NurikabeSolver.Deduction.new([
			{"pos": Vector2i(1, 0), "value": NurikabeUtils.CELL_WALL},
		], NurikabeSolver.DeductionReason.JOINED_ISLAND)
	assert_deduction(solver.deduce_joined_island(init_model()), expected)


func test_deduce_joined_island_3() -> void:
	grid = [
		" 1      ",
		"   2   3",
		"        ",
		"        ",
	]
	var expected: NurikabeSolver.Deduction = NurikabeSolver.Deduction.new([
			{"pos": Vector2i(1, 0), "value": NurikabeUtils.CELL_WALL},
			{"pos": Vector2i(0, 1), "value": NurikabeUtils.CELL_WALL},
			{"pos": Vector2i(2, 1), "value": NurikabeUtils.CELL_WALL},
		], NurikabeSolver.DeductionReason.JOINED_ISLAND)
	assert_deduction(solver.deduce_joined_island(init_model()), expected)


func test_deduce_joined_island_mistake() -> void:
	grid = [
		" 2 . 2",
		"      ",
		"      ",
		"      ",
		" 2   2",
	]
	var expected: NurikabeSolver.Deduction = NurikabeSolver.Deduction.new([
			{"pos": Vector2i(1, 4), "value": NurikabeUtils.CELL_WALL},
		], NurikabeSolver.DeductionReason.JOINED_ISLAND)
	assert_deduction(solver.deduce_joined_island(init_model()), expected)


func test_deduce_joined_island_none() -> void:
	grid = [
		" 2    ",
		"     2",
	]
	var expected: NurikabeSolver.Deduction = NurikabeSolver.Deduction.new([
		], NurikabeSolver.DeductionReason.JOINED_ISLAND)
	assert_deduction(solver.deduce_joined_island(init_model()), expected)


func test_deduce_unclued_island_invalid() -> void:
	# the grid already has an island with no clue; don't perform this deduction
	grid = [
		" .##  ",
		"##   2",
	]
	var expected: NurikabeSolver.Deduction = NurikabeSolver.Deduction.new([
		], NurikabeSolver.DeductionReason.UNCLUED_ISLAND)
	assert_deduction(solver.deduce_unclued_island(init_model()), expected)


func test_deduce_unclued_island_invalid_2() -> void:
	# the grid already has an island with no clue; don't perform this deduction
	grid = [
		"## 3##",
		"## .  ",
		"      ",
	]
	var expected: NurikabeSolver.Deduction = NurikabeSolver.Deduction.new([
		], NurikabeSolver.DeductionReason.UNCLUED_ISLAND)
	assert_deduction(solver.deduce_unclued_island(init_model()), expected)


func test_deduce_unclued_island_1() -> void:
	grid = [
		" 2  ##",
		"####  ",
	]
	var expected: NurikabeSolver.Deduction = NurikabeSolver.Deduction.new([
			{"pos": Vector2i(2, 1), "value": NurikabeUtils.CELL_WALL},
		], NurikabeSolver.DeductionReason.UNCLUED_ISLAND)
	assert_deduction(solver.deduce_unclued_island(init_model()), expected)


func test_deduce_unclued_island_chokepoint() -> void:
	grid = [
		"  ##  ",
		" 3   .",
		"  ##  ",
	]
	var expected: NurikabeSolver.Deduction = NurikabeSolver.Deduction.new([
			{"pos": Vector2i(1, 1), "value": NurikabeUtils.CELL_ISLAND},
		], NurikabeSolver.DeductionReason.UNCLUED_ISLAND)
	assert_deduction(solver.deduce_unclued_island(init_model()), expected)


func test_deduce_unclued_island_chokepoint_2() -> void:
	grid = [
		" 5    ",
		"##    ",
		" .    ",
	]
	var expected: NurikabeSolver.Deduction = NurikabeSolver.Deduction.new([
			{"pos": Vector2i(1, 0), "value": NurikabeUtils.CELL_ISLAND},
			{"pos": Vector2i(1, 2), "value": NurikabeUtils.CELL_ISLAND},
		], NurikabeSolver.DeductionReason.UNCLUED_ISLAND)
	assert_deduction(solver.deduce_unclued_island(init_model()), expected)


func test_deduce_island_too_large_1() -> void:
	grid = [
		" 2 .  ",
	]
	var expected: NurikabeSolver.Deduction = NurikabeSolver.Deduction.new([
			{"pos": Vector2i(2, 0), "value": NurikabeUtils.CELL_WALL},
		], NurikabeSolver.DeductionReason.ISLAND_TOO_LARGE)
	assert_deduction(solver.deduce_island_too_large(init_model()), expected)


func test_deduce_island_too_large_2() -> void:
	grid = [
		" 2 .  ",
		"      ",
	]
	var expected: NurikabeSolver.Deduction = NurikabeSolver.Deduction.new([
			{"pos": Vector2i(0, 1), "value": NurikabeUtils.CELL_WALL},
			{"pos": Vector2i(1, 1), "value": NurikabeUtils.CELL_WALL},
			{"pos": Vector2i(2, 0), "value": NurikabeUtils.CELL_WALL},
		], NurikabeSolver.DeductionReason.ISLAND_TOO_LARGE)
	assert_deduction(solver.deduce_island_too_large(init_model()), expected)


func test_deduce_island_too_large_invalid() -> void:
	# the island is already too large; don't perform this deduction
	grid = [
		" 2 . .",
		"      ",
	]
	var expected: NurikabeSolver.Deduction = NurikabeSolver.Deduction.new([
		], NurikabeSolver.DeductionReason.ISLAND_TOO_LARGE)
	assert_deduction(solver.deduce_island_too_large(init_model()), expected)


func test_island_too_small_1() -> void:
	grid = [
		" 3    ",
	]
	var expected: NurikabeSolver.Deduction = NurikabeSolver.Deduction.new([
			{"pos": Vector2i(1, 0), "value": NurikabeUtils.CELL_ISLAND},
			{"pos": Vector2i(2, 0), "value": NurikabeUtils.CELL_ISLAND},
		], NurikabeSolver.DeductionReason.ISLAND_TOO_SMALL)
	assert_deduction(solver.deduce_island_too_small(init_model()), expected)


func test_island_too_small_multiple() -> void:
	grid = [
		" 2    ",
		"##    ",
		"##   3",
	]
	var expected: NurikabeSolver.Deduction = NurikabeSolver.Deduction.new([
			{"pos": Vector2i(1, 0), "value": NurikabeUtils.CELL_ISLAND},
		], NurikabeSolver.DeductionReason.ISLAND_TOO_SMALL)
	assert_deduction(solver.deduce_island_too_small(init_model()), expected)


func test_island_too_small_chokepoint() -> void:
	grid = [
		" 4    ",
		"##  ##",
		"      ",
	]
	var expected: NurikabeSolver.Deduction = NurikabeSolver.Deduction.new([
			{"pos": Vector2i(1, 0), "value": NurikabeUtils.CELL_ISLAND},
			{"pos": Vector2i(1, 1), "value": NurikabeUtils.CELL_ISLAND},
		], NurikabeSolver.DeductionReason.ISLAND_TOO_SMALL)
	assert_deduction(solver.deduce_island_too_small(init_model()), expected)


func test_island_too_small_chokepoint_2() -> void:
	grid = [
		" 4  ##",
		"##  ##",
		"      ",
	]
	var expected: NurikabeSolver.Deduction = NurikabeSolver.Deduction.new([
			{"pos": Vector2i(1, 0), "value": NurikabeUtils.CELL_ISLAND},
			{"pos": Vector2i(1, 1), "value": NurikabeUtils.CELL_ISLAND},
			{"pos": Vector2i(1, 2), "value": NurikabeUtils.CELL_ISLAND},
		], NurikabeSolver.DeductionReason.ISLAND_TOO_SMALL)
	assert_deduction(solver.deduce_island_too_small(init_model()), expected)


func test_pools_1() -> void:
	grid = [
		" 4    ",
		"    ##",
		"  ####",
	]
	var expected: NurikabeSolver.Deduction = NurikabeSolver.Deduction.new([
			{"pos": Vector2i(1, 1), "value": NurikabeUtils.CELL_ISLAND},
		], NurikabeSolver.DeductionReason.POOLS)
	assert_deduction(solver.deduce_pools(init_model()), expected)


func test_pools_cut_off() -> void:
	grid = [
		" 5    ",
		"  ##  ",
		"  ##  ",
	]
	var expected: NurikabeSolver.Deduction = NurikabeSolver.Deduction.new([
			{"pos": Vector2i(0, 1), "value": NurikabeUtils.CELL_ISLAND},
			{"pos": Vector2i(1, 0), "value": NurikabeUtils.CELL_ISLAND},
			{"pos": Vector2i(2, 0), "value": NurikabeUtils.CELL_ISLAND},
			{"pos": Vector2i(2, 1), "value": NurikabeUtils.CELL_ISLAND},
		], NurikabeSolver.DeductionReason.POOLS)
	assert_deduction(solver.deduce_pools(init_model()), expected)


func test_no_split_walls_1() -> void:
	grid = [
		" 3##  ",
		"     3",
		"  ##  ",
	]
	var expected: NurikabeSolver.Deduction = NurikabeSolver.Deduction.new([
			{"pos": Vector2i(1, 1), "value": NurikabeUtils.CELL_WALL},
		], NurikabeSolver.DeductionReason.SPLIT_WALLS)
	assert_deduction(solver.deduce_split_walls(init_model()), expected)


func test_no_split_walls_2() -> void:
	grid = [
		"## 4  ",
		"      ",
		"    ##",
	]
	var expected: NurikabeSolver.Deduction = NurikabeSolver.Deduction.new([
			{"pos": Vector2i(0, 1), "value": NurikabeUtils.CELL_WALL},
		], NurikabeSolver.DeductionReason.SPLIT_WALLS)
	assert_deduction(solver.deduce_split_walls(init_model()), expected)


func assert_deduction(actual: NurikabeSolver.Deduction, expected: NurikabeSolver.Deduction) -> void:
	assert_eq(sorted_changes(actual.changes), sorted_changes(expected.changes))
	assert_eq(actual.reason, expected.reason)


func init_model() -> NurikabeBoardModel:
	return NurikabeTestUtils.init_model(grid)


func sorted_changes(changes: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = changes.duplicate()
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["pos"] < b["pos"])
	return result
