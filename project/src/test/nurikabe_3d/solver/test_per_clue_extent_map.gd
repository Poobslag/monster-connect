extends GutTest

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

var grid: Array[String] = []

func test_extent_cells() -> void:
	grid = [
		" . .  ",
		" 5##  ",
		"  ####",
		"    ##",
		"   . 5",
	]
	assert_extent_cells(Vector2i(2, 4), [
		Vector2i(0, 3), Vector2i(0, 4),
		Vector2i(1, 3), Vector2i(1, 4),
		Vector2i(2, 4),
	])


func test_extent_cells_neighbors() -> void:
	grid = [
		" . .  ",
		" 5##  ",
		"  ####",
		" 5 .##",
		" .    ",
	]
	assert_extent_cells(Vector2i(0, 3), [
		Vector2i(0, 3), Vector2i(0, 4),
		Vector2i(1, 3), Vector2i(1, 4),
		Vector2i(2, 4),
	])
	assert_extent_size(Vector2i(0, 3), 5)


func test_extent_cells_neighbors_2() -> void:
	grid = [
		"##########",
		" 3## . 4##",
		" .   .####",
		"       2  ",
	]
	assert_extent_cells(Vector2i(2, 1), [
		Vector2i(2, 1), Vector2i(2, 2),
		Vector2i(3, 1),
	])


func assert_extent_cells(island_cell: Vector2i, expected: Array[Vector2i]) -> void:
	var pcem: PerClueExtentMap = init_per_clue_extent_map()
	var island: CellGroup = pcem.board.get_island_for_cell(island_cell)
	var actual: Array[Vector2i] = pcem.get_extent_cells(island)
	actual.sort()
	expected.sort()
	assert_eq(actual, expected)


func assert_extent_size(island_cell: Vector2i, expected: int) -> void:
	var pcem: PerClueExtentMap = init_per_clue_extent_map()
	var island: CellGroup = pcem.board.get_island_for_cell(island_cell)
	var actual: int = pcem.get_extent_size(island)
	assert_eq(actual, expected)


func init_per_clue_extent_map() -> PerClueExtentMap:
	var board: SolverBoard = SolverTestUtils.init_board(grid)
	return PerClueExtentMap.new(board)
