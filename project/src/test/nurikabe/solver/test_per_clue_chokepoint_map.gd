extends GutTest

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

var grid: Array[String] = []

func test_chokepoint_cells_small() -> void:
	grid = [
		"   2####",
		"       5",
		"        ",
	]
	assert_chokepoint_cells(Vector2i(3, 1), {
		Vector2i(1, 1): CELL_WALL,
		Vector2i(1, 2): CELL_ISLAND,
		Vector2i(2, 2): CELL_ISLAND,
	})
	assert_chokepoint_cells(Vector2i(1, 0), {
	})


func test_chokepoint_cells_large() -> void:
	grid = [
		"   2####",
		"       5",
		"     . .",
	]
	assert_chokepoint_cells(Vector2i(3, 1), {
		Vector2i(1, 1): CELL_WALL,
		Vector2i(1, 2): CELL_ISLAND,
	})


func test_chokepoint_cells_clueless_island() -> void:
	grid = [
		"        ",
		" . 5####",
		"       5",
		" . .    ",
	]
	assert_chokepoint_cells(Vector2i(3, 2), {
		Vector2i(0, 2): CELL_WALL,
		Vector2i(1, 2): CELL_WALL,
		Vector2i(2, 3): CELL_ISLAND,
	})


func test_component_cells() -> void:
	grid = [
		" . .  ",
		" 5##  ",
		"  ####",
		"    ##",
		"   . 5",
	]
	assert_component_cells(Vector2i(2, 4), [
		Vector2i(0, 3), Vector2i(0, 4),
		Vector2i(1, 3), Vector2i(1, 4),
		Vector2i(2, 4),
	])


func test_component_cells_neighbors() -> void:
	grid = [
		" . .  ",
		" 5##  ",
		"  ####",
		" 5 .##",
		" .    ",
	]
	assert_component_cells(Vector2i(0, 3), [
		Vector2i(0, 3), Vector2i(0, 4),
		Vector2i(1, 3), Vector2i(1, 4),
		Vector2i(2, 4),
	])


func test_component_cells_neighbors_2() -> void:
	grid = [
		"##########",
		" 3## . 4##",
		" .   .####",
		"       2  ",
	]
	assert_component_cells(Vector2i(2, 1), [
		Vector2i(2, 1), Vector2i(2, 2),
		Vector2i(3, 1),
	])


func test_get_reachable_clues_by_cell() -> void:
	grid = [
		"    ####",
		" 2  ## .",
		"       .",
		"        ",
		" 6      ",
		"       5",
	]
	var pccm: PerClueChokepointMap = init_per_clue_chokepoint_map()
	var reachable_clues_by_cell: Dictionary[Vector2i, Dictionary] = pccm.get_reachable_clues_by_cell()
	assert_eq([Vector2i(3, 5)], reachable_clues_by_cell.get(Vector2i(3, 1), {} as Dictionary[Vector2i, bool]).keys())


func assert_chokepoint_cells(island_cell: Vector2i, expected: Dictionary[Vector2i, int]) -> void:
	var pccm: PerClueChokepointMap = init_per_clue_chokepoint_map()
	var actual: Dictionary[Vector2i, int] = pccm.find_chokepoint_cells(island_cell)
	assert_eq(actual, expected)


func assert_component_cells(island_cell: Vector2i, expected: Array[Vector2i]) -> void:
	var pccm: PerClueChokepointMap = init_per_clue_chokepoint_map()
	var actual: Array[Vector2i] = pccm.get_component_cells(island_cell)
	actual.sort()
	expected.sort()
	assert_eq(actual, expected)


func init_per_clue_chokepoint_map() -> PerClueChokepointMap:
	var board: SolverBoard = SolverTestUtils.init_board(grid)
	return PerClueChokepointMap.new(board)
