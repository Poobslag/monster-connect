extends GutTest

const CELL_EMPTY: String = NurikabeUtils.CELL_EMPTY
const CELL_INVALID: String = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: String = NurikabeUtils.CELL_ISLAND
const CELL_WALL: String = NurikabeUtils.CELL_WALL

var grid: Array[String] = []

func test_choke_island_small() -> void:
	grid = [
		"   2####",
		"       5",
		"        ",
	]
	assert_choke_island(Vector2i(3, 1), {
		Vector2i(1, 1): CELL_WALL,
		Vector2i(1, 2): CELL_ISLAND,
		Vector2i(2, 2): CELL_ISLAND,
	})
	assert_choke_island(Vector2i(1, 0), {
	})


func test_choke_island_large() -> void:
	grid = [
		"   2####",
		"       5",
		"     . .",
	]
	assert_choke_island(Vector2i(3, 1), {
		Vector2i(1, 1): CELL_WALL,
		Vector2i(1, 2): CELL_ISLAND,
	})


func test_choke_island_clueless_island() -> void:
	grid = [
		"        ",
		" . 5####",
		"       5",
		" . .    ",
	]
	assert_choke_island(Vector2i(3, 2), {
		Vector2i(0, 2): CELL_WALL,
		Vector2i(1, 2): CELL_WALL,
		Vector2i(2, 3): CELL_ISLAND,
	})


func assert_choke_island(island_cell: Vector2i, expected: Dictionary[Vector2i, String]) -> void:
	var pccm: PerClueChokepointMap = init_per_clue_chokepoint_map()
	var actual: Dictionary[Vector2i, String] = pccm.choke_island(island_cell)
	assert_eq(actual, expected)


func init_per_clue_chokepoint_map() -> PerClueChokepointMap:
	var board: FastBoard = FastTestUtils.init_board(grid)
	return PerClueChokepointMap.new(board)
